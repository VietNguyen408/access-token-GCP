#!/bin/bash
#
#This program will get a GCP token to log in to Google Cloud Platform

#Get Keycloak access token through curl command
curl -d client_id=admin-cli -d client_secret=8e2f9510-f34c-4dec-a01a-10d3d046412a -d username=admin -d password=admin -d grant_type=password http://127.0.0.1:8081/auth/realms/master/protocol/openid-connect/token | jq . >keycloak-access-token.json
KEYCLOAK_ACESS_TOKEN=$(jq -r .access_token keycloak-access-token.json)

#Authorize in Keycloak and get gcp-token in user Viet
curl \
	-H "Authorization: bearer $KEYCLOAK_ACESS_TOKEN" \
	"http://127.0.0.1:8081/auth/admin/realms/master/users/7676dcd5-03ce-446e-8045-7ba0dbf6e558" | jq . >gcp-token-keycloak.json

#Parse JSON to get gcp-refresh-token
GCP_REFRESH_TOKEN=$(jq -r '.attributes["GCP-refresh-token"][]' gcp-token-keycloak.json)
echo "The GCP refresh token is $GCP_REFRESH_TOKEN"
#Exchange GCP refresh token for a new access token
APP_CLIENT_ID="790131216438-2g4tmjsldi9a861m59uple5d1bvigfft.apps.googleusercontent.com"
APP_CLIENT_SERCRET="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"

curl \  --request POST \  --data "client_id=$APP_CLIENT_ID&client_secret=$APP_CLIENT_SERCRET&refresh_token=$GCP_REFRESH_TOKEN&grant_type=refresh_token" "https://accounts.google.com/o/oauth2/token" | jq . >gcp-new-access-token.json

GCP_NEW_ACCESS_TOKEN=$(jq -r .access_token gcp-new-access-token.json)
touch GCP_NEW_ACCESS_TOKEN.txt
destdir=GCP_NEW_ACCESS_TOKEN.txt

if [ -f "$destdir" ]; then
	echo "$GCP_NEW_ACCESS_TOKEN" >"$destdir"
fi

echo "The new GCP access token is $GCP_NEW_ACCESS_TOKEN"

#https://stackoverflow.com/questions/66940072/get-google-oauth2-access-token-using-only-curl
