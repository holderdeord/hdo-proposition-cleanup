Setup
-----

    $ createdb hdo_proposition_cleanup
    $ bundle install
    $ bundle exec rake db:reset import PROPOSITION_XML=/hdo/hdo-folketingparser/rawdata/forslag-vedtak-2009-2011/forslag-ikke-verifiserte-2010-2011.xml DECISION_XML=/hdo/hdo-folketingparser/rawdata/forslag-vedtak-2009-2011/vedtak-2009-2010.xml
    $ bundle exec foreman start