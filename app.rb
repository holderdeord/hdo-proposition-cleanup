require 'sinatra'
require File.expand_path("../db", __FILE__)

set :public_folder, File.expand_path("../public", __FILE__)

get '/' do
  @propositions = Proposition.order(:voterings_tidspunkt).all

  erb :index
end