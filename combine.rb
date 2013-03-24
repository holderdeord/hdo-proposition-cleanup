require 'json'
require 'pp'
require 'set'
require 'pry'

$stderr.puts "Reading results"
results = JSON.parse(File.read("vote-results.2009-2010.json"))

$stderr.puts "Reading votes"
all_votes = Dir['data/**/*.json'].map { |file| JSON.parse(File.read(file)).merge('url' => file) }.group_by { |v| v['time'] }

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

all_votes.each do |time, votes|
  votes.each do |v|
    props = Array(v['propositions'])

    if props.empty?
      raise "missing props: #{v['time']} @ #{v['url']}"
    end

    props.each do |prop|
      if prop['metadata'] && prop['metadata']['status'] != 'approved'
        raise "not approved #{v['url']}: #{prop['metadata'].inspect}"
      end

      if prop['body'].nil? || prop['body'].strip.empty?
        raise "no proposition body: #{v['url']}"
      end
    end


    if v['subject'].size > 255
      raise "subject is too long @ #{v['url']}"
    end
  end

  case votes.size
  when 2
    reps = results.delete(time)

    enacted, not_enacted = votes.partition { |e| e['enacted'] }.map(&:first)

    if !enacted['personal'] || !not_enacted['personal']
      $stderr.puts "non-personal alternate vote, fixing"
      enacted['personal'] = true
      not_enacted['personal'] = true
    end

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

final_votes = all_votes.values.flatten

puts "\ntotal votes: #{final_votes.size}"

if results.any?
  raise "found #{results.size} unused votes at #{results.keys.inspect}"
end

f = File.open("votes.2009-2010.json", "w") do |io|
  io << final_votes.to_json
end

p f