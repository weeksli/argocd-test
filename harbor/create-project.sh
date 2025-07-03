#!/bin/bash

endpoint= # http://harbor
id= # id
pass= # pass
project=$1

curl -X POST -u "$id:$pass" -H "Content-Type: application/json" -ki $endpoint/api/v2.0/projects -d'{"project_name": '"\"${project}\""', "public": true, "storage_limit": 0 }'