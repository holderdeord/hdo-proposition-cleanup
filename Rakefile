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

task :write do
  mkdir_p 'data'
  chdir 'data'

  coll.find.each do |vote|
    vote.delete('_id')
    time = vote['time']

    path = time.localtime.strftime("%Y/%m/%d/%H%M%S-#{vote['externalId'].gsub /\W/, '-'}.json")

    mkdir_p File.dirname(path)
    p path
    File.open(path, "w") do |file|
      file << JSON.pretty_generate(vote)
    end
  end
end

task :bad do
  count = 0

  data = []

  coll.find('propositions.metadata' => {:$exists => true}).each do |vote|
    next unless vote['propositions'].any? { |e| e['metadata']['status'] == 'rejected' }
    count += 1

    str = ['%s -> %s' % [vote['time'].localtime, vote['subject']]]
    str << "   http://stortinget.no/no/Saker-og-publikasjoner/Publikasjoner/Referater/Stortinget/2010-2011/#{vote['time'].strftime("%y%m%d")} "
    vote['propositions'].each do |prop|
      str << "\t#{prop.values_at('description', 'metadata').inspect}"
    end

    data << {:time => vote['time'], :str => str}
  end

  data.sort_by { |e| e[:time] }.each { |e| puts e[:str] }

  puts "count: #{count}"
end

task :stat do
  require 'pp'

  votes = coll.find('propositions.metadata.username' => {:$exists => true})
  counts = Hash.new { |h, k| h[k] = Hash.new(0) }

  votes.each do |vote|
    vote['propositions'].each do |prop|
      username = prop['metadata'] && prop['metadata']['username']
      status = prop['metadata'] && prop['metadata']['status']

      counts[username.to_s.downcase][status] += 1
      counts[username.to_s.downcase]['total'] += 1
    end
  end

  pp counts.sort_by { |n, d| d['total'] }
end