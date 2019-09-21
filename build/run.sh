#!/bin/sh

additional_cmd=""
 BASE_URL="http://localhost:8080/"

if [[ "${ENV}" == "dev" ]]; then
    additional_cmd="-D"
fi

if [[ -n "$URL" ]]; then
    BASE_URL="${URL}"
fi

hugo server --port ${PORT} --bind=0.0.0.0 --disableLiveReload ${additional_cmd} --appendPort=false --baseURL ${BASE_URL} 
