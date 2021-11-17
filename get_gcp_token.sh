#!/bin/bash
#
#This program will get a GCP token to log in to Google Cloud Platform

#Get Keycloak access token through curl command
curl -d 'client_id=admin_cli' -d 'client_secret=YOUR_CLIENT_SERCRET' -d 'username=YOUR_USERNAME' -d 'password=YOUR_PASSWORD' -d 'grant_type=password' 'http://localhost:8080/auth/realms/YOUR_REALM_NAME/protocol/openid-connect/token' | jq . >keycloak-access-token.json
KEYCLOAK_ACESS_TOKEN=$(jq -r .access_token keycloak-access-token.json)

#Authorize in Keycloak and get gcp-token in user Viet
curl \
	-H "Authorization: bearer $KEYCLOAK_ACESS_TOKEN" \
	"http://localhost:8080/auth/admin/realms/YOUR_REALM_NAME/users/YOUR_USER_ID" | jq . >gcp-token-keycloak.json

#Parse JSON to get gcp-refresh-token
GCP_REFRESH_TOKEN=$(jq -r '.attributes["GCP-refresh-token"][]' gcp-token-keycloak.json)
echo "The GCP refresh token is $GCP_REFRESH_TOKEN"

#Exchange GCP refresh token for a new access token
APP_CLIENT_ID="YOUR_APP_CLIENT_ID"
APP_CLIENT_SERCRET="YOUR_APP_CLIENT_SERCRET"

curl \  --request POST \  --data "client_id=$APP_CLIENT_ID&client_secret=$APP_CLIENT_SERCRET&refresh_token=$GCP_REFRESH_TOKEN&grant_type=refresh_token" "https://accounts.google.com/o/oauth2/token" | jq . >gcp-new-access-token.json

GCP_NEW_ACCESS_TOKEN=$(jq -r .access_token gcp-new-access-token.json)

#Save the GCP_NEW_ACCESS_TOKEN to a file to use it in Jenkins pipeline
touch GCP_NEW_ACCESS_TOKEN.txt
destdir=GCP_NEW_ACCESS_TOKEN.txt

if [ -f "$destdir" ]; then
	echo "$GCP_NEW_ACCESS_TOKEN" >"$destdir"
fi
echo "The new GCP access token is $GCP_NEW_ACCESS_TOKEN"
