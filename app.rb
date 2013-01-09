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
    (@timestamps_by_date ||= timestamps.group_by { |t| t.strftime("%Y-%m-%d") })[date]
  end

  def votes_at(timestamp)
    t = Time.parse(timestamp)
    @votes.select { |e| Time.parse(e['time']) == t }
  end

  def percentage_good
    40.0
  end

  def percentage_bad
    10.0
  end

end

DB = Database.new

set :public_folder, File.expand_path('../public', __FILE__)
enable :sessions

get '/' do
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
  content_type :json
  DB.dates.to_json
end

get '/dates/:date/timestamps' do |date|
  content_type :json
  DB.timestamps_for(date).to_json
end

get '/votes/:timestamp' do |ts|
  content_type :json
  DB.votes_at(ts).to_json
end
