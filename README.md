# GitHub PR Auditor

This tool audits pull requests in order to determine whether or not they are considered compliant. This solution is geared more towards those that do not have access to the [Audit Log API](https://docs.github.com/en/organizations/keeping-your-organization-secure/reviewing-the-audit-log-for-your-organization#using-the-audit-log-api) (i.e. [non-Enterprise users](https://github.com/pricing)) or simply want a canned solution for searching for and alerting upon non-compliant pull requests.

If a pull request is found by `GITHUB_SEARCH_QUERY`, it will log it as a non-compliant pull request and provide a link to it.

## Getting Started

### Configuration

The following environment variables are required at runtime:

| Variable            |                               Description                               |
| ------------------- | :---------------------------------------------------------------------: |
| AFTER_DATE          |    A date that follows the ISO8601 standard. Defaults to 1 day ago.     |
| BEFORE_DATE         | A date that follows the ISO8601 standard. Defaults to the present time. |
| GITHUB_API_TOKEN    |      A Github Personal Access Token (PAT) that has the repo scope.      |
| GITHUB_ORG_NAME     |                      The GitHub Org name to scan.                       |
| GITHUB_SEARCH_QUERY | The search query syntax. Defaults to `is:pr is:merged review:required`  |

To read more about how GitHub's search syntax works, see [understanding the search syntax](https://docs.github.com/en/github/searching-for-information-on-github/getting-started-with-searching-on-github/understanding-the-search-syntax).

### Execution

This requires [ruby](https://www.ruby-lang.org/en/documentation/installation/) to be installed on your machine. It was tested on `Ruby 2.7`. Other versions may work.

```shell
bundler install
GITHUB_API_TOKEN='<INSERT-PAT-HERE>' GITHUB_ORG_NAME='your-github-org' ./src/auditor.rb
```

## Deploy to AWS

The auditor can also be deployed to AWS via [aws-sam-cli](https://github.com/aws/aws-sam-cli). It requires an existing S3 bucket.

It works by running the auditor code in AWS Lambda on a schedule (Amazon CloudWatch Events), keeping track of the last successful run time in a Parameter Store parameter.

This also includes CloudWatch Alarms that will alarm upon:

- Any non-compliant pull request
- Missing logs (if no logs appear for 24 hours)
- Generic runtime errors

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
