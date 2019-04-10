#!/bin/bash

set -e

if [ ! -f Gemfile.lock ]; then
  touch Gemfile.lock
fi
if [ ! -f .env ]; then
  touch .env
fi
docker-compose build
docker-compose run test bundle
docker-compose run test bundle exec rake spec
docker-compose run test bundle exec rake install

cd pkg
LATEST_FILE=`ls -rt|tail -1`

echo
echo 'Hooray!!!  Gem has been built.  Now you should:'
echo '  cd pkg'
echo "  gem push $LATEST_FILE"
