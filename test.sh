#!/bin/bash -ex

docker ps

docker-compose down --rmi 'local' --volumes

function finish {
  echo 'Removing test environment'
  echo '---'
  docker-compose down --rmi 'local' --volumes
  rm -f tmp/pids/server.pid
}
trap finish EXIT

export COMPOSE_PROJECT_NAME=conjurdev


docker-compose build conjur-service-broker
docker-compose up -d conjur pg

sleep 10
api_key=$(docker-compose exec conjur bash -T -c 'rails r "puts Role[%Q{cucumber:user:admin}].api_key" 2>/dev/null')
echo "API KEY: $api_key"
export CONJUR_AUTHN_API_KEY="$api_key"

docker-compose up -d conjur-service-broker tests
docker-compose run tests ci/test.sh
