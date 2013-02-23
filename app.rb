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
    @timestamps ||= @votes.distinct('time').to_a.map { |e| Time.parse(e) }.sort.uniq.map { |e| e.localtime }
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
    votes = @votes.find(:time => Time.parse(timestamp)).to_a
    votes.each { |e| e['time'] = e['time'].localtime }

    votes
  end

  def insert_vote(vote)
    vote['time'] = Time.parse(vote['time']) unless vote['time'].kind_of?(Time)

    clear_caches
    @votes.insert vote
  end

  def find_by_external_id(xid)
    @votes.find_one(:externalId => xid)
  end

  def clear_caches
    @timestamps = nil
    @proposition_count = nil
    @dates = nil
  end

  def save_votes(votes)
    votes.each do |vote|
      if vote['delete']
        @votes.remove(:externalId => vote['externalId'])
        clear_caches
      else
        xvote = find_by_external_id(vote['externalId']) or next

        xvote['subject']      = vote['subject']
        xvote['time']         = Time.parse(vote['time'])
        xvote['propositions'] = vote['propositions']

        @votes.save(xvote)
      end
    end

    # clear cache
    @proposition_count = nil

    votes.reject { |e| e['delete'] }
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

post '/split/' do
  data = JSON.parse(request.body.read)
  vote = DB.find_by_external_id(data['externalId'])
  vote || halt(404, 'ikke funnet')

  vote.delete('_id')

  vote['counts']['for']     = data['counts']['against']
  vote['counts']['against'] = data['counts']['for']
  vote['enacted']           = !data['enacted']

  if data['externalId'] =~ /^(.+?)(n?e)?$/
    vote['externalId'] = "#{$1}#{(vote['enacted'] ? 'e' : 'ne')}"
  else
    vote['externalId'] << (vote['enacted'] ? 'e' : 'ne')
  end

  vote['splitBy'] = params[:username]
  vote['representatives'].each do |rep|
    rep['voteResult'] = rep['voteResult'] == 'for' ? 'against' : 'for'
  end

  DB.insert_vote(vote)

  vote.to_json
end

post '/insert/' do
  vote = JSON.parse(request.body.read)

  if DB.find_by_external_id(vote['externalId'])
    halt 422, ' externalId (timestamp + enacted) er ikke unik'
  else
    DB.insert_vote(vote)
  end
end

get '/env' do
  ENV.to_hash.to_json
end

delete '/caches' do
  DB.clear_caches
end
