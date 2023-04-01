# AWS
Miscellaneous AWS scripts

## aws_dynamo_tables

Bash script to query the item count in DynamoDB tables across multiple AWS regions and output it in tabular format.

Bash version 4.0 or later, the AWS CLI tool, and the [jq](https://stedolan.github.io/jq/) tool are required. [GNU Parallel](https://www.gnu.org/software/parallel/) is optional.

### Usage

`aws_dynamo_tables.sh [ -S ] [-C ] [ -a ] [ -p ] [ -r regions ]`

With no option, the script will get an item count for all DynamoDB
tables in the user's default AWS region. This is the region configured
in `.aws/config` or in the `AWS_DEFAULT_REGION` environment variable.

The `-a` option specifies all regions defined in the script; the `-p` option specifies the regions defined as "production" regions in the script. `-r` can be used to pass specific regions to the script.

By default, the output of the script is in pretty-printed tabular format. The `-C` option changes the output to CSV format. Tables that don't exist in a region will have a `-` as an item count. All diagnostic output and error messages go to `stderr`.

The script tries to use GNU Parallel (if installed) to get counts for each table by region, the `-S` option overrides this behavior.
