#!/bin/bash

set -e

docker-compose build
docker-compose run test bundle
docker-compose run test bundle exec rake install
docker-compose run test bundle exec rake spec

cd pkg
LATEST_FILE=`ls -rt|tail -1`

echo
echo 'Hooray!!!  Gem has been built.  Now you should:'
echo '  cd pkg'
echo "  gem push $LATEST_FILE"