
LOG_RETENTION_IN_DAYS ?= 731

build:
	sam build

package: build
	sam package \
		--template-file template.yml \
		--output-template-file out.yml \
		--s3-bucket "$(BUCKET_NAME)" \
		--region "$(REGION)" \

validate:
	sam validate

deploy: package
	sam deploy \
		--template-file out.yml \
		--stack-name $(STACK_NAME) \
	 	--s3-bucket $(BUCKET_NAME) \
		--region $(REGION) \
		--capabilities CAPABILITY_NAMED_IAM \
	 	--parameter-overrides "$$(cat $(SAM_PARAMS_PATH) | tr '\n' ' ')"
	$(MAKE) set-log-policy


set-log-policy:
# Set the lambda log group retention policy,
# https://github.com/aws/serverless-application-model/issues/257#issuecomment-461896365
	@lambda_log_group_name=$$(aws --region "$(REGION)" cloudformation describe-stacks --stack-name "$(STACK_NAME)" --query "Stacks[0].Outputs[?OutputKey=='LambdaLogGroup'].OutputValue" --output text); \
	aws logs put-retention-policy \
		--region "$(REGION)" \
		--log-group-name "$$lambda_log_group_name" \
		--retention-in-days "$(LOG_RETENTION_IN_DAYS)"

destroy:
	aws cloudformation delete-stack --stack-name "$(STACK_NAME)"

