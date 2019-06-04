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


MACOS_ERROR_MACRO='ifelse(index('${MACHTYPE#*-}',apple),0,
                   echo On macOS consider \"brew install TOOL\")'
TABLE_NAME_PRINT_MACRO='ifelse(CSV,t,echo -n ${table},
                        printf "%-${tw}s" ${table})'

if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    exec 1>&2
    echo "ERROR: $0 requires GNU bash version 4.0 or later"
    eval "$(m4 -D TOOL=bash <<< ${MACOS_ERROR_MACRO})"
    exit 128
fi

declare -a all_regions=( us-east-1 eu-central-1 ap-southeast-1 us-west-2 )
declare -a prod_regions=( us-east-1 eu-central-1 ap-southeast-1 )

function usage() {
    echo "Usage: $0 [ -S ] [ -C ] [ -a ] [ -p ] [ -r regions ]" 1>&2
    exit 1
}

declare -a regions=( )
declare serial=nil csv=nil
while getopts ":SCapr:" options; do
    case ${options} in
        S) serial=t ;;
        C) csv=t ;;
        a) regions=( "${all_regions[@]}" ) ;;
        p) regions=( "${prod_regions[@]}" ) ;;
        r) rflag=t ;;
        *) usage ;;
    esac
done
if [[ -v rflag ]]; then
    shift $(( OPTIND-2 ))
    regions=( "$@" )
fi

function main() {
    check_aws
    check_regions
    
    declare -A regions_by_table
    declare -A tables_by_region
    fetch_tables


    declare -i rw tw
    if [[ ${serial} == nil && ! -x $(which parallel) ]]; then
        serial=t
    fi
    fetch_print_items
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
        eval "$(m4 -D TOOL=jq <<< ${MACOS_ERROR_MACRO})"
        exit 128
    fi
}

function check_regions() {
    mapfile < <(aws --output json ec2 describe-regions |
                    jq --raw-output ".Regions[].RegionName")
    for region in "${regions[@]}"; do
        if [[ ! ${MAPFILE[*]}  =~ ${region} ]]; then
            echo "ERROR: Incorrect region ${region}" 1>&2
            exit 1
        fi
    done
}

function fetch_tables() {
    echo "Retrieving AWS DynamoDB tables..." 1>&2
    for region in "${regions[@]}"; do
        local list
        list=$(aws dynamodb --output text --region ${region} list-tables 2>/dev/null)
        list=${list//TABLENAMES/}
        # Build up two associative arrays
        # regions_by_table is structured for output
        # tables_by_region is optimized for parallel item fetching
        tables_by_region[${region}]=${list}
        for table in ${list}; do
            regions_by_table[${table}]+="${region} "
        done
    done
}

function fetch_print_items() {
    # If parallel, prefetch all tables and fill in output array later
    # If serial, fill in the output array one item at a time
    if [[ ${serial} == nil ]]; then
        local -A tables_and_items_by_region=( )
        echo "Please wait..." 1>&2
        for region in "${!tables_by_region[@]}"; do
            tables_and_items_by_region[${region}]=$(parallel --will-cite --jobs 0 --keep-order \
                'aws --output json --region '${region}' dynamodb describe-table \
                     --table-name {} | jq --raw-output ".Table|(.TableName,.ItemCount)"' \
                     ::: ${tables_by_region[${region}]})
        done
    fi
    print_table_header
    for table in $(tr ' ' '\n' <<<  "${!regions_by_table[@]}" | sort); do
        local -A items=( )
        eval "$(m4 -D CSV=${csv} <<< ${TABLE_NAME_PRINT_MACRO})"
        for region in "${regions[@]}" ; do
            local item
            case ${serial} in
                t)
                    if [[ ${regions_by_table[${table}]} =~ ${region} ]]; then
                        item=$(aws --output json --region ${region} \
                                   dynamodb describe-table --table-name ${table} | \
                                   jq ".Table.ItemCount")
                        items[${region}]=${item}
                    fi;;
                nil)
                    if [[ ${tables_and_items_by_region[${region}]} =~ ${table} ]]; then
                        item=$(sed -n "/${table}/{n;p;}" <<< ${tables_and_items_by_region[${region}]})
                        items[${region}]=${item}
                    fi;;
            esac
        done
        print_item_counts
    done
}

function print_table_header() {
    local table_keys=${!regions_by_table[*]}
    eval "$(echo "r " "${regions[@]}" ";t " "${table_keys[@]}" |
        awk 'BEGIN {rw=0; tw=0}
             function size()
             {
             for (i=2; i<=NF; i++) {
                 cur=length($i)
                 max=(cur>max?cur:max)
                 }
             return(max)
             }
             /^r / {
                   rw=size()
                   # expect >10^9 items
                   rw=(rw<14?14:rw)
                   }            
             /^t / {tw=size()}
             END {
                  printf "rw=%d tw=%d\n", ++rw, ++tw
                 }' RS=\;)"

    if [[ ${csv} == nil ]]; then
        printf "%-${tw}s" "TABLE"
        for region in "${regions[@]}"; do
            printf "%${rw}s" ${region^^}
        done
    else
        echo -n "TABLE"
        for region in "${regions[@]}"; do echo -n ",${region^^}"; done
    fi
    echo
}

function print_item_counts() {
    if [[ ${csv} == nil ]]; then
        for region in "${regions[@]}" ; do
            if [[ ! -v items[${region}] ]]; then
                printf "%${rw}s" "-"
            else
                printf "%'${rw}d" ${items[${region}]}
            fi
        done
    else
        for region in "${regions[@]}" ; do
            if [[ ! -v items[${region}] ]]; then
                echo -n ,-
            else
                echo -n ",${items[${region}]}"
            fi
        done
    fi
    echo
}

main

exit 0
