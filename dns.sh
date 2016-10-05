#!/usr/bin/env bash
shopt -s nocasematch

if [[ "$#" -lt 2 ]]; then
  echo "action (create/delete) and environment (sandbox/prod) must be provided as command line arguments" > /dev/stderr
  exit 52
fi

if [[ "$3" =~ dry-?run ]]; then
  DRYRUN='dry-run'
  echo "Dry-run mode enabled" > /dev/stderr
else
  DRYRUN=''
fi

set -euo pipefail
IFS=$'\n\t'
REGION="us-west-2"

if [[ "$2" =~ sandbox ]]; then
  CNAME_HOSTNAME="crowd.us-west-2.sandbox.dwolla.net"
  PRIVATE_ZONE="false"
  ZONE_NAME="us-west-2.sandbox.dwolla.net"
elif [[ "$2" =~ prod ]]; then
  CNAME_HOSTNAME="crowd.dwolla.net"
  PRIVATE_ZONE="true"
  ZONE_NAME="dwolla.net"
else
  echo "second argument must be \`sandbox\` or \`prod\`" > /dev/stderr
  exit 51
fi

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
                     --dns-name ${ZONE_NAME} | \
                     jq -r ".HostedZones | map(select(.Config.PrivateZone == $PRIVATE_ZONE)) | map(.Id) | .[0]")

if [[ "$1" =~ create ]]; then
  ACTION="CREATE"
  COMMENT="add ${CNAME_HOSTNAME} to ${HOSTED_ZONE_ID}"
  CNAME_TARGET="jenkins-linux.dwolla.net"
elif [[ "$1" =~ delete ]]; then
  ACTION="DELETE"
  COMMENT="remove ${CNAME_HOSTNAME} from ${HOSTED_ZONE_ID}"
  CNAME_TARGET=$(aws route53 list-resource-record-sets \
                     --region us-west-2 \
                     --hosted-zone ${HOSTED_ZONE_ID} | \
                 jq -r ".ResourceRecordSets | map(select(.Name == \"${CNAME_HOSTNAME}.\")) | .[0].ResourceRecords | map(.Value) | .[0]")
else
  echo "first argument must be \`create\` or \`delete\`" > /dev/stderr
  exit 50
fi

JSON=$(cat << __EOF__
{
  "Comment": "${COMMENT}",
  "Changes": [
    {
      "Action": "${ACTION}",
      "ResourceRecordSet": {
        "Name": "${CNAME_HOSTNAME}",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "${CNAME_TARGET}"
          }
        ]
      }
    }
  ]
}
__EOF__
)

echo ${JSON} | jq .

if [[ ${DRYRUN} != "dry-run" ]]; then
  echo ${JSON} | jq . | aws route53 --region ${REGION} change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file:///dev/stdin
fi
