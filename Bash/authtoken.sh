#!/bin/sh

tenantID=""
applicationID=""
clientKey=""
resource="https://graph.microsoft.com/.default"
#jsonstring='{"grant_type":"client_credentials","client_id":"'$applicationID'","client_secret=$clientKey","resource":"'$resource'"}'
#echo "${jsonstring}" | jq
authtokenretrieval () {
	#Retrieve Authentication Token from MS Graph (OAuth, not MSAL)
	echo "Retrieving Authentication Token"
	#https://login.microsoftonline.com/$tenantid/oauth2/token
	msauthtoken=$(curl "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" \
		-X POST  -H "Content-Type: application/x-www-form-urlencoded" \
		--data-urlencode "client_id=$applicationID" \
		--data-urlencode "scope=$resource" \
		--data-urlencode "client_secret=$clientKey" \
		--data-urlencode "grant_type=client_credentials" | jq -j .access_token)
	msauthtoken=`sed -e 's/^"//' -e 's/"$//' <<<"$msauthtoken"`
	#echo $msauthtoken > authtoken
	#TOKEN=$(cat authtoken)
	#echo $TOKEN
	#PAYLOAD=$(echo $msauthtoken | awk -F'.' '{print $2}' | base64 -d 2>/dev/null) # extract payload and base64 decode
	#echo $PAYLOAD | jq .

	#echo $msauthtoken

	#Send API CALL to RETRIEVE USER INFO AND VERIFY IF USER EXISTS
	#theuser="testchris@brandwatch.com"
	#baseurl="https://graph.microsoft.com/v1.0"
	#url=$baseurl + '/users/' + $theuser
	echo "Calling MSGraph to see if User exists"
	read -p "What's the user's email?" theuser #this needs to be the upn/full brandwatch email
	baseurl="https://graph.microsoft.com/v1.0/users/$theuser"
	msuserinfo=$(curl "$baseurl" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $msauthtoken" | jq .)
	echo $msuserinfo
}
authtokenretrieval
#IF EXISTS Send API CALL to DELETE USER

#ElseIF DOESN'T EXIST, OUTPUT "USER DOESN'T EXIST"

#elseif Error then echo "Error while attempting to reach MSGraph, review logs" >> MSGraph.logfile

