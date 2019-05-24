#!/usr/bin/env bash
#
#  aws_dynamo_tables.sh [ -S ] [-C ] [ -a ] [ -p ] [ -r regions ]
#
#  -S query serially
#  -C CSV output
#  -a all regions
#  -p production
#  -r regions
#
#  default region is configured in .aws/config or AWS_DEFAULT_REGION
#


MACOS_ERROR_MACRO='if [[ ${MACHTYPE} =~ apple ]]; then
                       echo On macOS consider \"brew install TOOL\";
                   fi'

if [[ ${BASH_VERSINFO[0]} -lt 4 ||
      ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -lt 3 ]]; then
    exec 1>&2
    echo "ERROR: $0 requires GNU bash version 4.3 or later"
    eval $(m4 -D TOOL=bash <<< ${MACOS_ERROR_MACRO})
    exit 128
fi

declare -a all_regions=( us-east-1 eu-central-1 ap-southeast-1 us-west-2 )
declare -a prod_regions=( us-east-1 eu-central-1 ap-southeast-1 )

function usage() {
    echo "Usage: $0 [ -S ] [ -C ] [ -a ] [ -p ] [ -r regions ]" 1>&2
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
        eval $(m4 -D TOOL=jq <<< ${MACOS_ERROR_MACRO})
        exit 128
    fi
}

function check_regions() {
    mapfile < <(aws --output json ec2 describe-regions |
                    jq --raw-output ".Regions[].RegionName")
    for region in ${regions[@]}; do
        if [[ ! ${MAPFILE[@]}  =~ ${region} ]]; then
            echo "ERROR: Incorrect region ${region}" 1>&2
            exit 1
        fi
    done
}

function fetch_tables() {
    echo "Retrieving AWS DynamoDB tables..." 1>&2
    for region in ${regions[@]}; do
        local list
        list=$(aws dynamodb --output text --region ${region} list-tables 2>/dev/null)
        list=${list//TABLENAMES/}
        # Build up two tables
        # regions_by_table is structured for output
        # tables_by_region is optimized for parallel item fetching
        tables_by_region[${region}]=${list}
        for table in ${list[@]}; do
            regions_by_table[${table}]+="${region} "
        done
    done
}

function print_header() {

    function header_width() {
        local -n arrayref=$1
        echo $(( $(for item in ${arrayref[@]}; do
                       echo ${#item}; done | sort -n | tail -1)
                 +1 ))
    }

    # calculate field widths; expect >10^9 items
    rw=$(header_width regions)
    rw=$(( ${rw} < 15 ? 15 : ${rw} ))

    local table_keys=${!regions_by_table[@]}
    tw=$(header_width table_keys)

    if [[ ! -v csv ]]; then
        printf "%-${tw}s" "TABLE"
        for region in ${regions[@]}; do
            printf "%${rw}s" ${region^^}
        done
    else
        echo -n "TABLE"
        for region in ${regions[@]}; do echo -n ",${region^^}"; done
    fi
    echo
}

function collect_item_count() {
    local table=$1
    local region=$2
    echo $(aws --output json --region ${region} dynamodb describe-table --table-name ${table} | \
                           jq ".Table.ItemCount")
}

function collect_item_count_parallel() {
    local table=$1; shift
    local table_regions=$*
    echo $(parallel --keep-order aws --output json --region {} dynamodb describe-table \
             --table-name ${table} '|' jq ".Table.ItemCount" ::: ${table_regions})
}

function fetch_print_items() {
    local -a counts=( )
    for table in $(tr ' ' '\n' <<<  ${!regions_by_table[@]} | sort); do
        local -A items=( )
        if [[ ! -v csv ]]; then
            printf "%-${tw}s" ${table}
        else
            echo -n  ${table}
        fi
        fetch_item_counts
        print_item_counts
    done
}

function fetch_item_counts() {
    if [[ ! -v serial && -x $(which parallel) ]]; then
        counts=($(collect_item_count_parallel ${table} ${regions_by_table[${table}]}))
        for region in ${regions_by_table[${table}]}; do
            items[${region}]=${counts}
            counts=(${counts[@]:1})
        done
    else
        for region in ${regions[@]} ; do
            if [[ ${regions_by_table[${table}]} =~ ${region} ]]; then
                items[${region}]=$(collect_item_count ${table} ${region})
            fi
        done
    fi
}

function print_item_counts() {
    if [[ ! -v csv ]]; then
        for region in ${regions[@]} ; do
            if [[ ! -v items[${region}] ]]; then
                printf "%${rw}s" "-"
            else
                printf "%'${rw}d" ${items[${region}]}
            fi
        done
    else
        for region in ${regions[@]} ; do
            if [[ ! -v items[${region}] ]]; then
                echo -n ,-
            else
                echo -n ",${items[${region}]}"
            fi
        done
    fi
    echo
}

declare -a regions=( )
while getopts ":SCapr:" options; do
    case ${options} in
        S) serial=t ;;
        C) csv=t ;;
        a) regions=${all_regions[@]} ;;
        p) regions=${prod_regions[@]} ;;
        r) rflag=t ;;
        *) usage ;;
    esac
done
if [[ -v rflag ]]; then
    shift $(($OPTIND-2))
    regions=$@
fi

check_aws
check_regions

declare -A regions_by_table
declare -A tables_by_region
fetch_tables

declare -i rw tw
print_header
fetch_print_items

exit 0
