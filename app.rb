require 'sinatra'
require 'pry'
require 'json'
require 'pp'
require 'time'
require 'mongo'

class Database
  def initialize
    @conn  = Mongo::MongoClient.new
    @votes = @conn.db('proposition-cleanup').collection('votes')
  end

  def timestamps
    @timestamps ||= @votes.distinct('time').to_a.sort.uniq.map { |e| e.localtime }
  end

  def dates
    @dates ||= timestamps.map { |time| time.strftime("%Y-%m-%d") }.uniq
  end

  def votelist_for(date)
    date = Date.parse(date)

    votes = @votes.find(:time => {
      :$gte => date.to_time,
      :$lte => (date + 1).to_time
    })

    votes = votes.map do |e|
      {
        :time            => e['time'],
        :subject         => e['subject'],
        :externalIssueId => e['externalIssueId']
      }
    end

    groups = votes.group_by { |e| e[:externalIssueId] }.values
    groups.each { |group| group.sort_by! { |e| e[:time] } }
    groups.sort_by { |e| e.first[:time] }
  end

  def votes_at(timestamp)
    @votes.find(:time => Time.parse(timestamp)).to_a
  end

  def insert_vote(vote)
    @votes.insert vote.merge('time' => Time.parse(vote['time']))
  end

  def save_votes(votes, username)
    votes.each do |vote|
      xvote = @votes.find_one(:externalId => vote['externalId'])

      Array(vote['propositions']).each do |prop|
        next unless prop['metadata']

        if prop['metadata']['status']
          prop['metadata']['username'] = username
        else
          prop['metadata'].delete('username')
        end
      end

      xvote['propositions'] = vote['propositions']
      @votes.save(xvote)
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

get '/votelist/:date' do |date|
  DB.votelist_for(date).to_json
end

get '/votes/:timestamp' do |ts|
  DB.votes_at(ts).to_json
end

post '/votes/' do
  votes = JSON.parse(request.body.read)
  DB.save_votes(votes, session[:username]).to_json
end

post '/import' do
  DB.insert_vote(JSON.parse(request.body.read))
end

get '/env' do
  ENV.to_hash.to_json
end