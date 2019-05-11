#!/usr/bin/env bash
#
#  aws_dynamo_tables.sh [ -a ] [ -p ] [ -r regions ]
#
#  -a all regions
#  -p production
#  -r regions
#
#  default region is configured in .aws/config or AWS_DEFAULT_REGION
#

if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    exec 1>&2
    echo "ERROR: $0 requires GNU bash version 4.0 or later"
    if [[ ${MACHTYPE} =~ apple ]]; then
        echo 'On macOS consider "brew install bash"'
    fi
    exit 128
fi

function usage() {
    echo "Usage: $0 [ -a ] [ -p ] [ -r regions ]" 1>&2
    exit 1
}

function check_aws() {
    if [[ -x "$(which aws)" ]]; then
        while IFS= read -r; do
            if [[ ${REPLY} =~ _key[[:space:]]+'<not set>' ]]; then
                echo 'ERROR: AWS CLI tool not configured with credentials' 1>&2
                exit 128
            fi
            if [[ ! -v regions && ${REPLY} =~ region ]]; then
                if [[ ! ${REPLY} =~ None$ ]]; then
                    set -- ${REPLY}
                    regions=$2
                else
                    usage
                fi
            fi
        done < <(aws configure list | tail +3)
    else
        exec 1>&2
        echo "ERROR: $0 requires the AWS CLI tool to be installed"
        if [[ ${MACHTYPE} =~ apple|linux ]]; then
            echo 'Install the AWS CLI tool using "pip install awscli"'
        fi
        exit 128
    fi
    if [[ ! -x "$(which jq)" ]]; then
	exec 1>&2
	echo "ERROR: $0 requires the jq tool to be installed"
	if [[ ${MACHTYPE} =~ apple ]]; then
            echo 'On macOS consider "brew install jq"'
	fi
	exit 128
    fi
}

function fetch_tables() {
    echo "Retrieving AWS DynamoDB tables..."
    for region in ${regions[@]}; do
        for table in $(aws dynamodb --output text --region ${region} list-tables | cut -f2); do
            tables[${table}]+=${region}
        done
    done
}

function print_header() {
    # calculate field width
    let rw=$(for region in ${regions[@]}; do echo ${#region}; done | sort -n | tail -1)+1
    let tw=$(for table in ${!tables[@]}; do echo ${#table}; done | sort -n | tail -1)+1

    printf "%-${tw}s" "DYNAMO TABLE"
    for region in ${regions[@]}; do
        printf "%${rw}s" ${region^^}
    done
    echo
}

function collect_item_count() {
    local region=$1
    local table=$2
    echo $(aws --output json --region ${region} dynamodb describe-table --table-name ${table} | \
                           jq ".Table.ItemCount")
}

function print_item_counts() {
    for table in $(tr ' ' '\n' <<<  ${!tables[@]} | sort); do
        printf "%-${tw}s" ${table}
        declare -A items=( )
        for region in ${regions[@]} ; do
            if [[ ${tables[${table}]} =~ ${region} ]]; then
                items[${region}]=$(collect_item_count ${region} ${table})
            fi
        done
        for region in ${regions[@]} ; do
            if [[ ! -v items[${region}] ]]; then
                printf "%${rw}s" "-"
            else
                printf "%'${rw}d" ${items[${region}]}
            fi
        done
        echo
    done
}

unset regions
while getopts ":apr:" options; do
    case ${options} in
        a)
            regions=( us-east-1 eu-central-1 ap-southeast-1 us-west-2 )
            ;;
        p)
            regions=( us-east-1 eu-central-1 ap-southeast-1 )
            ;;
        r)
            regions=( )
            ;;
        *)
            usage
            ;;
    esac
    if [[ -z ${regions} ]]; then
        shift; regions=$@
    fi
done      

check_aws

declare -A tables
fetch_tables
print_header
print_item_counts

exit 0
