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

This requires [ruby](https://www.ruby-lang.org/en/documentation/installation/) to be installed on your machine. It was tested on `Ruby 3.2.2`. Other versions may work.

```shell
bundler install
GITHUB_API_TOKEN='<INSERT-PAT-HERE>' GITHUB_ORG_NAME='your-github-org' ./src/auditor.rb
```

## Deploy to AWS

The auditor can also be deployed to AWS via [aws-sam-cli](https://github.com/aws/aws-sam-cli). It requires an existing S3 bucket.

It works by running the auditor code in AWS Lambda on a schedule (Amazon CloudWatch Events), keeping track of the last successful run time in a Parameter Store parameter.

![diagram](https://user-images.githubusercontent.com/4519234/122277304-bff67500-ceb3-11eb-8bfd-4ef8d3fa7e42.png)

This also includes CloudWatch Alarms that will alarm upon:

- Any non-compliant pull request
- Missing logs (if no logs appear for 24 hours)
- Generic runtime errors

### Requirements

- [awscli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [aws-sam-cli](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)

### Running the deploy script

For example, to deploy the CloudFormation stack:

```sh
make deploy-staging \
  STACK_NAME=github-pr-auditor \
  BUCKET_NAME=my-sam-bucket \
  REGION=us-east-1 \
  SAM_PARAMS_PATH=sam-params/example.cfg
```

### Destroying

To destroy all of the resources provisioned:

```sh
make destroy STACK_NAME=github-pr-auditor
```

## Development

### Setup

To setup the dev environment, run:

```sh
bundle install --with development
pre-commit install # optional (requires pre-commit)
```
