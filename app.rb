require 'sinatra'
require 'pry'
require 'json'
require 'pp'
require 'time'

class Database
  attr_reader :votes, :representatives

  def initialize
    @representatives, @votes = [], []

    JSON.parse(File.read(File.expand_path('../votes-2010-2011.min.json', __FILE__))).each do |data|
      case data['kind']
      when 'hdo#representative'
        @representatives << data
      when 'hdo#vote'
        @votes << data
      else
        puts "unknown kind: #{data['kind']}"
      end
    end

    @votes = @votes.sort_by { |e| Time.parse(e['time']) }
  end

  def timestamps
    @timestamps ||= @votes.map { |e| Time.parse(e['time']) }.uniq
  end

  def dates
    @dates ||= timestamps.map { |time| time.strftime("%Y-%m-%d") }.uniq
  end

  def timestamps_for(date)
    (@votes_by_date ||= @votes.group_by { |t| Time.parse(t['time']).strftime("%Y-%m-%d") })
    @votes_by_date[date].map do |e|
      {:time => e['time'], :subject => e['subject']}
    end
  end

  def votes_at(timestamp)
    t = Time.parse(timestamp)
    @votes.select { |e| Time.parse(e['time']) == t }
  end

  def stats
    all = propositions

    processed = all.select { |prop| prop['metadata'] && prop['metadata']['status'] }
    good      = processed.select { |prop| prop['metadata']['status'] == 'approved' }
    bad       = processed.select { |prop| prop['metadata']['status'] == 'rejected' }

    stats = {
      :good      => good.size * 100 / all.size,
      :bad       => bad.size * 100 / all.size,
      :processed => processed.size * 100 / all.size,
      :total     => all.size
    }

    stats
  end

  def propositions
    @votes.flat_map { |e| e['propositions'] }
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
