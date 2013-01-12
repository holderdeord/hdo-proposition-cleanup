require 'open-uri'
require 'mongo'
require 'json'
require 'time'
require 'logger'

def coll
  @coll ||= Mongo::MongoClient.new.db('proposition-cleanup').collection('votes')
end

task :import do
  coll.remove

  JSON.parse(File.read(File.expand_path('../votes-2010-2011.min.json', __FILE__))).each do |data|
    case data['kind']
    when 'hdo#representative'
      # do nothing
    when 'hdo#vote'
      coll.insert data.merge('time' => Time.parse(data['time']))
    else
      puts "unknown kind: #{data['kind']}"
    end

    print "."
  end
end

task :load do
  sh "ssh jaribakken.com 'mongoexport -d proposition-cleanup -c votes' | mongoimport --drop -d proposition-cleanup -c votes"
end

task :stat do
  votes = coll.find('propositions.metadata.username' => {:$exists => true})
  counts = Hash.new(0)

  votes.each do |vote|
    vote['propositions'].each do |prop|
      counts[prop['metadata']['username']] += 1
    end
  end

  p counts
end