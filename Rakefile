require 'open-uri'
require 'nokogiri'
require 'pry'

PROPOSITION_URL = ENV['PROPOSITION_XML'] || "https://raw.github.com/holderdeord/hdo-folketingparser/master/rawdata/forslag-vedtak-2009-2011/forslag-ikke-verifiserte-2010-2011.xml"
DECISION_URL    = ENV['DECISION_XML']    || "https://raw.github.com/holderdeord/hdo-folketingparser/master/rawdata/forslag-vedtak-2009-2011/vedtak-2009-2010.xml"

task :env do
  require File.expand_path("../db", __FILE__)
end

namespace :import do
  task :propositions => :env do
    puts "downloading propositions.."
    data = Nokogiri.XML(open(PROPOSITION_URL))

    puts "importing propositions..."
    data.css("IkkeKvalSikreteForslag").each do |node|
      fbt = node.css("Forslagsbetegnelse").first
      fst = node.css("ForslagTekst").first

      Proposition.create!(
        :mote_kartnr        => Integer(node.css("MoteKartNr").first.inner_text),
        :dagsorden_saksnr   => Integer(node.css("DagsordenSaksNr").first.inner_text),
        :voteringstidspunkt => Time.parse(node.css("VoteringsTidspunkt").first.inner_text),
        :forslagsbetegnelse => fbt && fbt.inner_text,
        :forslagstekst      => fst && fst.inner_text
      )
    end
  end

  task :decisions => :env do
    puts "downloading decisions.."
    data = Nokogiri.XML(open(DECISION_URL))

    puts "importing decisions..."
    data.css("Vedtak").each do |node|
      fbt = node.css("Forslagsbetegnelse").first
      fst = node.css("Vedtakstekst").first
      pva = node.css("PaaVegneAv").first

      Decision.create!(
        :kartnr             => Integer(node.css("KartNr").first.inner_text),
        :saksnr             => Integer(node.css("SaksNr").first.inner_text),
        :forslagsbetegnelse => fbt && fbt.inner_text,
        :vedtakstekst       => fst && fst.inner_text,
        :on_behalf_of       => pva && pva.inner_text
      )
    end
  end
end

task :import => %w(import:propositions import:decisions)

namespace :db do
  task :create => :env do
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE propositions (
          id                 serial PRIMARY KEY,
          mote_kartnr        integer NOT NULL,
          dagsorden_saksnr   integer NOT NULL,
          voteringstidspunkt timestamp NOT NULL,
          forslagsbetegnelse text,
          forslagstekst      text
      );

      CREATE TABLE decisions (
          id                 serial PRIMARY KEY,
          kartnr             integer NOT NULL,
          saksnr             integer NOT NULL,
          forslagsbetegnelse text,
          vedtakstekst       text,
          on_behalf_of       character varying(255)
      );
    SQL
  end

  task :drop => :env do
    connection = ActiveRecord::Base.connection

    begin
      connection.drop_table Proposition.table_name
    rescue => ex
      p [ex.class, ex.message]
    end

    begin
      connection.drop_table Decision.table_name
    rescue => ex
      p [ex.class, ex.message]
    end
  end

  task :reset => %w[drop create]
end