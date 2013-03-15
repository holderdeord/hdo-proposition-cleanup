require 'json'
require 'pp'
require 'set'
require 'pry'

$stderr.puts "Reading results"
results = JSON.parse(File.read("vote-results.2009-2010.json"))

$stderr.puts "Reading votes"
votes = Dir['data/**/*.json'].map { |file| JSON.parse(File.read(file)).merge('url' => file) }.group_by { |v| v['time'] }

all_votes = votes.map do |time, votes|
  case votes.size
  when 2
    $stderr.print 'A'
    # TODO: handle alternates
    results.delete(time)
  when 1
    vote = votes.first
    unless vote['personal']
      $stderr.print 'E'
      next
    end

    $stderr.print "."

    reps = results.delete(time) { raise "no results for #{time.inspect}" }
    vote['counts'] = Hash.new(0)
    reps.each { |e| vote['counts'][e['voteResult']] += 1 }
    vote['representatives'] = reps
  else
    # raise "invalid vote count for #{time.inspect}: #{votes.size} #{votes.map { |e| e['url'] }}"
    $stderr.print votes.size
  end

  votes
end

if results.any?
  raise "found unused #{results.size} unused votes"
end

