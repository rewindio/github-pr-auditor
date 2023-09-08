#!/usr/bin/env ruby
# frozen_string_literal: true

# This is a wrapper around ./auditor.rb that keeps track of
# time last run by using SSM parameter store.
# It's likely safer to use a DynamoDB table with a lock,
# but since the concurrency of the Lambda is set to 1,
# it is unlikely there will be a chance of collision,
# and any side effects from a collision would have minimal impact.

require 'json'
require 'aws-sdk'

SSM_CLIENT = Aws::SSM::Client.new

def get_ssm_parameter(parameter_id)
  SSM_CLIENT.get_parameter(
    name: parameter_id,
    with_decryption: true,
  )
end

def update_ssm_parameter(parameter_id, value)
  SSM_CLIENT.put_parameter(
    name: parameter_id,
    overwrite: true,
    value: value,
  )
end

def github_token_from_ssm
  response = get_ssm_parameter(ENV['GITHUB_TOKEN_SSM_PATH'])
  response.parameter.value
end

def last_time_checked_from_ssm
  response = get_ssm_parameter(ENV['LAST_TIME_CHECKED_SSM_PATH'])
  if response.parameter.value == 'null'
    # On a fresh deploy, there won't be a last time,
    # so default to 1 day ago
    (DateTime.now - 1).iso8601(3)
  else
    response.parameter.value
  end
end

def handler(*)
  ENV['GITHUB_API_TOKEN'] = github_token_from_ssm
  ENV['AFTER_DATE'] = last_time_checked_from_ssm unless ENV['AFTER_DATE']
  ENV['BEFORE_DATE'] = DateTime.now.iso8601(3) unless ENV['BEFORE_DATE']
  require_relative './auditor'

  # Update parameter so that future invocations know which time was last checked
  update_ssm_parameter(ENV['LAST_TIME_CHECKED_SSM_PATH'], ENV['BEFORE_DATE'])

  {
    statusCode: 200,
    body: {}.to_json,
  }
end
