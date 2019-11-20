# Welcome to PuzzleTime

PuzzleTime is an open source time tracking and resource planning web application for SMEs.


## Development

PuzzleTime is a Ruby on Rails application that runs on Ruby >= 2.2.2 and Rails 5.
To get going, after you got a copy of PuzzleTime, issue the following commands in the main
directory:

    bin/setup            # install gem dependencies and setup database (PostgreSQL)
    rake                 # run all the tests
    rails db:setup       # prepare database
    rails server         # start the rails server

Alternatively you can use the [dockerized development](doc/development/02_docker.md) environment.

A more detailed development documentation in German can be found in [doc/development](doc/development/README.md). This is where you also find some [Deployment](doc/development/03_deployment.md) instructions

## Heroku

To deploy to heroku execute the following commands

    heroku create
    git push heroku ama/heroku_setup:master

    heroku config:set RAILS_SERVE_STATIC_FILES=true 
    heroku run rails assets:precompile

    heroku addons:create memcachier:dev

    heroku run rails db:migrate 
    heroku run 'ln -s /app/db/seeds/development /app/db/seeds/production && rails db:seed'
    heroku open

Then login using (username: mw, password: a) as credentials, if this doesnt work try to run 

    heroku restart

## License

PuzzleTime is released under the GNU Affero General Public License.
Copyright 2006-2017 by [Puzzle ITC GmbH](http://puzzle.ch).
See COPYING for more details.
