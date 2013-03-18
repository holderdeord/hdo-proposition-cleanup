require 'json'
require 'pp'
require 'set'
require 'pry'

$stderr.puts "Reading results"
results = JSON.parse(File.read("vote-results.2009-2010.json"))

$stderr.puts "Reading votes"
votes = Dir['data/**/*.json'].map { |file| JSON.parse(File.read(file)).merge('url' => file) }.group_by { |v| v['time'] }

def count_votes(results)
  Hash.new(0).tap do |counts|
    results.each { |e| counts[e['voteResult']] += 1 }
  end
end

def reverse_positions(results)
  results.map do |r|
    if r['voteResult'] == 'absent'
      r
    else
      r.merge 'voteResult' => (r['voteResult'] == 'for' ? 'against' : 'for')
    end
  end
end

all_votes = votes.map do |time, votes|
  case votes.size
  when 2
    reps = results.delete(time)

    if bad = votes.find { |e| not e['personal'] }
      print 'X'
      next
      # raise "non-personal alternate vote! #{bad['url']}"
    end
    $stderr.print 'A'

    enacted, not_enacted = votes.partition { |e| e['enacted'] }.map(&:first)

    counts = count_votes(reps)
    if counts['for'] > counts['against']
      enacted['counts']              = counts
      enacted['representatives']     = reps

      not_enacted['counts']          = {'for' => counts['against'], 'against' => counts['for'], 'absent' => counts['absent']}
      not_enacted['representatives'] = reverse_positions(reps)
    else
      not_enacted['counts']          = counts
      not_enacted['representatives'] = reps

      enacted['counts'] = {'for' => counts['against'], 'against' => counts['for'], 'absent' => counts['absent']}
      enacted['representatives'] = reverse_positions(reps)
    end
  when 1
    vote = votes.first
    unless vote['personal']
      $stderr.print 'E'
      next
    end

    $stderr.print "."

    reps = results.delete(time) { raise "no results for #{time.inspect}" }
    vote['counts'] = count_votes(reps)
    vote['representatives'] = reps
  else
    # raise "invalid vote count for #{time.inspect}: #{votes.size} #{votes.map { |e| e['url'] }}"
    $stderr.print votes.size
  end

  votes
end


puts "\ntotal votes: #{all_votes.size}"

if results.any?
  raise "found #{results.size} unused votes at #{results.keys.inspect}"
end

f = File.open("votes.2009-2010.json", "w") do |io|
  io << all_votes.compact.to_json
end

p f