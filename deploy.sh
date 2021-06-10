#!/usr/bin/env bash

# Builds and deploys resources

set -euo pipefail

programname=$0

usage() {
	echo "Usage:"
	echo ""
	echo "$programname <DEPLOY_BUCKET> <AWS_PROFILE> <STACK_NAME> <REGION> <PARAMETER_OVERRIDES>"
	echo ""
}

if [ "$#" -ne 5 ]; then
	usage
	exit 1
fi

dependencies=(aws sam)

check_dependency() {
	local dependency=$1
	if ! command -v "$dependency" &>/dev/null; then
		echo "missing"
	fi
}

dependency_error_msg() {
	local dependency=$1
	set +x
	echo -e '\033[0;31m'
	echo "ERROR: Missing dependency '$dependency'"
	echo -e '\033[0m'
	set -x
}

for d in "${dependencies[@]}"; do
	ret=$(check_dependency "$d")
	if [ "$ret" = "missing" ]; then
		dependency_error_msg "$d"
		exit 1
	fi
done

DEPLOY_BUCKET=$1
AWS_PROFILE=$2
STACK_NAME=$3
REGION=$4
PARAMETER_OVERRIDES=$5
LOG_RETENTION_IN_DAYS=731

# Ensure the correct AWS_PROFILE is used
export AWS_PROFILE=$AWS_PROFILE

set -x

sam build

sam package \
	--template-file template.yml \
	--output-template-file out.yml \
	--s3-bucket "${DEPLOY_BUCKET}" \
	--region "${REGION}" \
	--profile "${AWS_PROFILE}"

sam deploy \
	--template-file out.yml \
	--stack-name "${STACK_NAME}" \
	--capabilities CAPABILITY_IAM \
	--region "${REGION}" \
	--profile "${AWS_PROFILE}" \
	--parameter-overrides "${PARAMETER_OVERRIDES}"

# Set the lambda log group retention policy,
# https://github.com/aws/serverless-application-model/issues/257#issuecomment-461896365
lambda_log_group_name=$(aws --region "$REGION" cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='LambdaLogGroup'].OutputValue" --output text)
aws logs put-retention-policy \
	--region "$REGION" \
	--log-group-name "$lambda_log_group_name" \
	--retention-in-days "$LOG_RETENTION_IN_DAYS"
