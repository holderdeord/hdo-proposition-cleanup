require 'uri'
require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection ENV['DATABASE_URL'] || "postgres://hdo:@localhost/hdo_proposition_cleanup"
ActiveRecord::Base.logger = Logger.new(STDOUT)

class Proposition < ActiveRecord::Base
  MINUTES = "http://stortinget.no/no/Saker-og-publikasjoner/Publikasjoner/Referater/Stortinget/%s/%s"

  attr_accessible :mote_kartnr,
                  :dagsorden_saksnr,
                  :voteringstidspunkt,
                  :forslagsbetegnelse,
                  :forslagstekst

  def teaser
    Nokogiri.HTML(forslagstekst).inner_text.truncate(50)
  end

  def minutes_url
    MINUTES % ['2010-2011', voteringstidspunkt.strftime("%y%m%d")]
  end
end

class Decision < ActiveRecord::Base
  attr_accessible :kartnr,
                  :saksnr,
                  :forslagsbetegnelse,
                  :vedtakstekst,
                  :on_behalf_of

  def teaser
    Nokogiri.HTML(vedtakstekst).inner_text.truncate(50)
  end
end


