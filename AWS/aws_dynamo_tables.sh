#!/usr/bin/env bash

if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    exec 1>&2
    echo "ERROR: $0 requires GNU bash version 4.0 or later"
    if [[ ${MACHTYPE} =~ apple ]]; then
	echo 'On macOS consider "brew install bash"'
    fi
    exit 128
fi

unset tables; declare -A tables
declare -a regions=(us-east-1 eu-central-1 ap-southeast-1)

for region in ${regions[@]}; do
    for table in $(aws dynamodb --region ${region} list-tables | cut -f2); do
	tables[${table}]="${tables[${table}]} ${region}"
    done
done

let rw=$(for region in ${regions[@]}; do echo ${#region}; done | sort -n | tail -1)+1
let tw=$(for table in ${!tables[@]}; do echo ${#table}; done | sort -n | tail -1)+1

printf "%-${tw}s" "DYNAMO TABLE"
for region in ${regions[@]}; do
    printf "%${rw}s" ${region^^}
done
echo
for table in $(tr ' ' '\n' <<<  ${!tables[@]} | sort); do
    printf "%-${tw}s" ${table}
    for region in ${regions[@]} ; do
	if [[ ${tables[${table}]} =~ ${region} ]]; then
	    printf "%'${rw}d" $(aws --output json --region ${region} dynamodb describe-table --table-name ${table} | jq ".Table.ItemCount")
	else printf "%${rw}s" "-"
	fi
    done
    echo
done
