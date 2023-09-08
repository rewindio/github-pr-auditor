#!/usr/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'octokit'
require 'retriable'
require 'dotenv'

logger = Logger.new($stdout)
logger.level = Logger::INFO
logger.info('Starting PR auditor...')

# Configuration
Dotenv.parse('.env.local', '.env')
Dotenv.require_keys('GITHUB_API_TOKEN', 'GITHUB_ORG_NAME')

after_date = ENV['AFTER_DATE'] || (DateTime.now - 1).iso8601(3)
before_date = ENV['BEFORE_DATE'] || DateTime.now.iso8601(3)
org_name = ENV['GITHUB_ORG_NAME']
search_query = ENV['GITHUB_SEARCH_QUERY'] || 'archived:false is:pr is:merged review:required'

@client = Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'], per_page: 100, auto_paginate: true)

begin
  logger.info("Searching between #{after_date} - #{before_date}")
  search_results = []
  Retriable.retriable do
    search_results = @client.search_issues("org:#{org_name} closed:#{after_date}..#{before_date} #{search_query}")
  end
rescue => e
  logger.error("Unable to search for pull requests: #{e.message}")
  exit 1
end

search_results.items.each do |pr|
  repo_name = pr.repository_url.split('/')[-1]
  full_repo_name = "#{org_name}/#{repo_name}"
  pr_name = "#{full_repo_name}##{pr.number}"

  begin
    pr_metadata = nil
    Retriable.retriable do
      pr_metadata = @client.pull_request(full_repo_name, pr.number)
    end
  rescue => e
    logger.error("Unable to pull request metadata for '#{pr_name}': #{e.message}")
    next
  end

  logger.info("The pull request '#{pr_name}' by #{pr_metadata.merged_by.login} is non-compliant! #{pr_metadata.html_url}")
end
