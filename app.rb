require 'sinatra'
require 'pry'
require 'json'
require 'pp'
require 'time'
require 'mongo'

class Database
  def initialize
    database = 'proposition-cleanup'

    if ENV['VCAP_SERVICES']
      config   = JSON.parse(ENV['VCAP_SERVICES']).first.fetch('credentials')
      database = config['db']
      ENV['MONGODB_URI'] = "mongodb://#{config['username']}:#{config['password']}@#{config['hostname']}:#{config['port']}"
    end

    @conn  = Mongo::MongoClient.new
    @votes = @conn.db(database).collection('votes')
  end

  def timestamps
    @timestamps ||= @votes.distinct('time').to_a.sort.uniq.map { |e| e.localtime }
  end

  def dates
    @dates ||= timestamps.map { |time| time.strftime("%Y-%m-%d") }.uniq
  end

  def timestamps_for(date)
    date = Date.parse(date)
    @votes.find(:time => {:$gte => date.to_time, :$lte => (date + 1).to_time}).map do |e|
      {
        :time => e['time'],
        :subject => e['subject']
      }
    end.sort_by { |e| e[:time] }
  end

  def votes_at(timestamp)
    @votes.find(:time => Time.parse(timestamp)).to_a
  end

  def save_votes(votes)
    votes.each do |vote|
      existing = @votes.find_one(:externalId => vote['externalId']) or halt 404
      existing.merge!(vote.merge('time' => Time.parse(vote['time'])))

      @votes.save(existing)
    end

    votes
  end

  def stats
    good = @votes.find("propositions.metadata.status" => 'approved').count
    bad  = @votes.find("propositions.metadata.status" => 'rejected').count

    stats = {
      :good      => good,
      :bad       => bad,
      :processed => good + bad,
      :total     => @votes.count
    }

    stats
  end
end

DB = Database.new

set :public_folder, File.expand_path('../public', __FILE__)
enable :sessions

before do
  content_type :json
end

get '/' do
  content_type :html

  if session[:username]
    erb :index
  else
    erb :new_session
  end
end

post '/new_session' do
  session[:username] = params[:username]
  redirect '/'
end

get '/dates' do
  DB.dates.to_json
end

get '/stats' do
  DB.stats.to_json
end

get '/dates/:date/timestamps' do |date|
  DB.timestamps_for(date).to_json
end

get '/votes/:timestamp' do |ts|
  DB.votes_at(ts).to_json
end

post '/votes/' do
  votes = JSON.parse(request.body.read)
  DB.save_votes(votes).to_json
end

get '/env' do
  ENV.to_hash.to_json
end