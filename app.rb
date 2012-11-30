require 'sinatra'
require 'nokogiri'
require File.expand_path("../db", __FILE__)

PROPOSITION_PATH = '/forslag-2010-2011'
DECISION_PATH    = '/vedtak-2009-2010'

set :public_folder, File.expand_path("../public", __FILE__)

get '/' do
  redirect PROPOSITION_PATH
end

get PROPOSITION_PATH do
  @propositions = Proposition.order(:voteringstidspunkt).all
  erb :propositions
end

get DECISION_PATH do
  @decisions = Decision.order(:kartnr).all
  erb :decisions
end

get '/propositions/:id' do |id|
  @text = Proposition.select(:forslagstekst).find(id).forslagstekst.gsub(/<p\/?>/, '')
  erb :modal
end

get '/decisions/:id' do |id|
  @text = Decision.select(:forslagstekst).find(id).forslagstekst.gsub(/<p\/?>/, '')
  erb :modal
end

class String
  def truncate(length = 30, truncate_string = "...")
    l = length - truncate_string.size
    self.size > length ? self[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : self
  end
end