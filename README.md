# GitHub PR Auditor

This tool audits PRs in order to determine whether or not they were merged with appropriate approval.

If the pull request does not meet the acceptance criteria, it will log an error linking the non-compliant pull request.

At the moment, all requests are run synchronously so larger merge windows could take a while.

## Acceptance Criteria

- The pull request was merged with the minimum number of required approvals

## Getting Started

### Configuration

The following environment variables are required at runtime:

| Variable           |                               Description                               |
| ------------------ | :---------------------------------------------------------------------: |
| GITHUB_API_TOKEN   | A Github Personal Access Token (PAT) that has repo and admin:org scopes |
| GITHUB_ORG_NAME    |              The github org name to scan (i.e. 'rewindio')              |
| MERGED_AFTER_DATE  |    A date that follows the ISO8601 standard. Defaults to 1 day ago.     |
| MERGED_BEFORE_DATE | A date that follows the ISO8601 standard. Defaults to the present time. |

To read more about how GitHub's search syntax works, see [the docs](https://docs.github.com/en/github/searching-for-information-on-github/getting-started-with-searching-on-github/understanding-the-search-syntax).

### Execution

This requires [ruby](https://www.ruby-lang.org/en/documentation/installation/) to be installed on your machine. It was tested on `Ruby 2.7`. Other versions may work.

```shell
bundler install
GITHUB_API_TOKEN='<INSERT-PAT-HERE>' GITHUB_ORG_NAME='rewindio' ./src/auditor.rb
```

## Deploy to AWS

The auditor can also be deployed to AWS via [aws-sam-cli](https://github.com/aws/aws-sam-cli). It requires an existing S3 bucket.

It works by running the auditor code in AWS Lambda on a schedule (Amazon CloudWatch Events), keeping track of the last successful run time in a Parameter Store parameter.

### Requirements

- [awscli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [aws-sam-cli](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)

### Running the deploy script

For example, to deploy with a [Named profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) of `my-aws-staging-account`:

```sh
./deploy.sh 'aws-sam-bucket-github-pr-auditor' 'my-aws-staging-account' 'github-pr-auditor' 'us-east-1' 'AlarmSNSTopicArn=arn:aws:sns:us-east-1:000000000000:mytopic KMSDecryptSSMKeyID=t22cc86b-e043-4e65-828e-8f737121abc2'
```

### Destroying

To destroy all of the resources provisioned:

```sh
aws cloudformation delete-stack --stack-name 'github-pr-auditor'
```

## Development

### Setup

To setup the dev environment, run:

```sh
bundle install --with development
pre-commit install # optional (requires pre-commit)
```
