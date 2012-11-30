require 'uri'
require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection ENV['DATABASE_URL'] || "postgres://hdo:@localhost/hdo_proposition_cleaner"
ActiveRecord::Base.logger = Logger.new(STDOUT)

class Proposition < ActiveRecord::Base
  attr_accessible :mote_kart_nr,
                  :dagsorden_saks_nr,
                  :voterings_tidspunkt,
                  :forslags_betegnelse,
                  :forslags_tekst
end


