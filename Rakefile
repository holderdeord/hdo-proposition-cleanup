require 'open-uri'
require 'nokogiri'

URL = ENV['XML'] || "https://github.com/holderdeord/hdo-folketingparser/raw/master/rawdata/forslag-vedtak-2009-2011/forslag-ikke-verifiserte-2010-2011.xml"

task :env do
  require File.expand_path("../db", __FILE__)
end

task :import => :env do
  puts "downloading.."
  data = Nokogiri.XML(open(URL))

  puts "importing..."
  data.css("IkkeKvalSikreteForslag").each do |node|
    puts node

    fbt = node.css("Forslagsbetegnelse").first
    fst = node.css("ForslagTekst").first

    Proposition.create!(
      :mote_kart_nr        => Integer(node.css("MoteKartNr").first.inner_text),
      :dagsorden_saks_nr   => Integer(node.css("DagsordenSaksNr").first.inner_text),
      :voterings_tidspunkt => Time.parse(node.css("VoteringsTidspunkt").first.inner_text),
      :forslags_betegnelse => fbt && fbt.inner_text,
      :forslags_tekst      => fst && fst.inner_text
    )
  end
end

namespace :db do
  task :create => :env do
    Proposition.connection.execute <<-SQL
      CREATE TABLE propositions (
          id                  serial PRIMARY KEY,
          mote_kart_nr        integer NOT NULL,
          dagsorden_saks_nr   integer NOT NULL,
          voterings_tidspunkt timestamp NOT NULL,
          forslags_betegnelse text,
          forslags_tekst      text
      );
    SQL
  end

  task :drop => :env do
    Proposition.connection.drop_table Proposition.table_name
  end

  task :reset => %w[drop create]
end