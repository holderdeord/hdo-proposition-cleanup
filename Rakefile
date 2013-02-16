# encoding: utf-8

require 'open-uri'
require 'mongo'
require 'json'
require 'time'
require 'logger'
require 'nokogiri'
require 'digest/md5'
require 'pp'

def coll
  @coll ||= Mongo::MongoClient.new.db('proposition-cleanup').collection('votes')
end

namespace :disk do
  task :clean do
    Dir['data/**/*.json'].each do |path|
      p path
      vote = JSON.parse(File.read(path))
      vote['propositions'].each do |prop|
        raise "bad vote: #{vote.inspect}" if prop['body'].nil?
        prop['body'] = prop['body'].gsub("", "-").gsub("\r\n", "\n")
      end

      File.open(path, "w") { |file| file << JSON.pretty_generate(vote) }
    end
  end

  task :missing do
    files = Dir['data/**/*.json']
    puts files.select { |e| vote = JSON.parse(File.read(e)); vote['propositionsMissing'] }
  end

  task :spellcheck do
    require 'ffi-icu'
    require 'ffi/aspell'

    iterator = ICU::BreakIterator.new :word, 'nb'
    nb_speller = FFI::Aspell::Speller.new('nb')
    nn_speller = FFI::Aspell::Speller.new('nn')

    Dir['data/**/*.json'].each do |path|
      vote = JSON.parse(File.read(path))

      vote['propositions'].each do |prop|
        strs = []
        Nokogiri::HTML.parse(prop['body']).traverse { |e| strs << e.text if e.text? }
        iterator.text = strs.join(' ')

        invalid_words = []
        iterator.each_substring do |word|
          next if word =~ /^[\d\.,]+$|^M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$/
          invalid_words << word unless nb_speller.correct?(word) || nn_speller.correct?(word)
        end

        if invalid_words.any?
          puts "#{path}: #{invalid_words.uniq.inspect}"
        end
      end
    end
  end

  task :combine do
    $stdout.sync = true

    files = Dir['data/**/*.json']
    votes = []

    files.each do |file|
      vote = JSON.parse(File.read(file))

      vote['subject'].gsub!(/nr\.(\.)?(\d)/, 'nr. \2')

      if vote.member?('propositionsMissing')
        if vote['propositionsMissing']
          raise "missing propositions in #{file}: #{JSON.pretty_generate vote}"
        else
          vote.delete('propositionsMissing')
        end
      end

      props = vote['propositions']
      if props.empty?
        raise "no propositions in #{file}: #{JSON.pretty_generate vote}"
      end

      props.each do |prop|
        body = prop['body']
        if body.nil? || body.strip.empty? || Nokogiri::HTML.parse(body).text.strip.empty?
          raise "empty proposition body: #{file}: #{JSON.pretty_generate vote}"
        end

        prop['externalId'] = Digest::MD5.hexdigest(Time.parse(vote['time']).strftime("%Y-%m-%d") + body)

        if prop.member?('metadata')
          if prop['metadata']['status'] != 'approved'
            raise "rejected: #{file}"
          end

          prop.delete('metadata')
        end
      end

      print "."
      votes << vote
    end

    File.open('combined.json', 'w') do |io|
      io << JSON.generate(votes)
    end
  end

  task :rejected do
    Dir['data/**/*.json'].each do |file|
      vote = JSON.parse(File.read(file))
      if vote['propositions'].any? { |prop| prop['metadata'] && prop['metadata']['status'] != 'approved' }
        puts file
      end
    end
  end
end

namespace :db do
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
end
