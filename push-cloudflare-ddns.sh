#!/bin/bash

CF_API_TOKEN='APIR_xxxxxxxxxxxxxxxxxxxxxxxx'
DEVICE='eth0'
ZONE_ID='xxxxxx'
TO_UPDATE_DNS_RECORD='subdomain'
TO_UPDATE_DNS_DOMAIN='some-domain.cc'

ipv6=$(ip addr show dev ${DEVICE} | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d')

records_resp=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
-H "Content-Type:application/json")

dns_record_id=''
for row in $(echo ${records_resp} | jq -r '.result[] | @base64'); do
    _jq() {
        echo "${row}" | base64 --decode | jq -r "${1}"
    }
    _dns_record_id=$(_jq '.id')
    _dns_record_name=$(_jq '.name')
    if [ "${_dns_record_name}" == "${TO_UPDATE_DNS_RECORD}.${TO_UPDATE_DNS_DOMAIN}" ]; then
        dns_record_id="${_dns_record_id}"
    fi
done


curl -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${dns_record_id}" \
-H "Authorization: Bearer ${CF_API_TOKEN}" \
-H "Content-Type:application/json" \
-d "{\"type\":\"AAAA\",\"name\":\"${TO_UPDATE_DNS_RECORD}\",\"content\":\"${ipv6}\",\"proxied\":false}"
