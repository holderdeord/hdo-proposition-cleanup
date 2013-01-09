require 'open-uri'
require 'mongo'
require 'json'
require 'time'

task :import do
  coll = Mongo::Connection.new.db('proposition-cleanup').collection('votes')
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