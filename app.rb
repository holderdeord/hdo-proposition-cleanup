require 'sinatra'
require 'pry'
require 'json'
require 'pp'
require 'time'
require 'mongo'

class Time
  def to_json(opts = nil)
    strftime("%Y/%m/%d %H:%M:%S").to_json(opts)
  end
end

module Enumerable
  def uniq_by(&blk)
    h = {}

    each do |e|
      h[yield(e)] ||= e
    end

    h.values
  end
end

class Database
  def initialize
    @conn  = Mongo::MongoClient.new
    @votes = @conn.db('proposition-cleanup').collection('votes')
  end

  def timestamps
    @timestamps ||= @votes.distinct('time').to_a.sort.uniq.map { |e| e.localtime }
  end

  def dates
    @dates ||= timestamps.map { |time| time.strftime("%Y/%m/%d") }.uniq
  end

  def votelist_for(date)
    date = Date.parse(date)

    votes = @votes.find(:time => {
      :$gte => date.to_time,
      :$lte => (date + 1).to_time
    })

    votes = votes.map do |e|
      {
        :time            => e['time'].localtime,
        :subject         => e['subject'],
        :externalIssueId => e['externalIssueId']
      }
    end

    groups = votes.group_by { |e| e[:externalIssueId] || e }.values
    groups.map { |group|
      group.uniq_by { |e| e[:time] }.sort_by { |e| e[:time] }
    }.sort_by { |e| e.first[:time]}
  end

  def votes_at(timestamp)
    @votes.find(:time => Time.parse(timestamp)).to_a
  end

  def insert_vote(vote)
    @votes.insert vote.merge('time' => Time.parse(vote['time']))
  end

  def save_votes(votes)
    votes.each do |vote|
      xvote = @votes.find_one(:externalId => vote['externalId'])

      xvote['subject']      = vote['subject']
      xvote['time']         = Time.parse(vote['time'])
      xvote['propositions'] = vote['propositions']

      @votes.save(xvote)
    end

    votes
  end

  def stats
    votes = @votes.find({"propositions.metadata" => {:$exists => true}}, fields: ["propositions"]).to_a
    status_counts = Hash.new(0)

    votes.each do |e|
      e['propositions'].each do |prop|
        status = prop['metadata'] && prop['metadata']['status']
        status_counts[status] += 1
      end
    end

    stats = {
      :good      => status_counts['approved'],
      :bad       => status_counts['rejected'],
      :processed => status_counts['approved'] + status_counts['rejected'],
      :total     => proposition_count
    }

    stats
  end

  def proposition_count
    # cached since it won't change after boot
    @proposition_count ||= @votes.find({}, fields: ["propositions"]).flat_map { |e| e['propositions'] }.size
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
  DB.save_votes(votes).to_json
end

post '/import' do
  DB.insert_vote(JSON.parse(request.body.read))
end

get '/env' do
  ENV.to_hash.to_json
end
