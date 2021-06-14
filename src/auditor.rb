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
org_name = ENV['GITHUB_ORG_NAME']
merged_after_date = ENV['MERGED_AFTER_DATE'] || (DateTime.now - 1).iso8601(3)
merged_before_date = ENV['MERGED_BEFORE_DATE'] || DateTime.now.iso8601(3)

@client = Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'], per_page: 100, auto_paginate: true)

def count_approved_reviews(reviews)
  count = 0
  reviews.each do |review|
    count += 1 if review.state == 'APPROVED'
  end
  count
end

begin
  logger.info("Collecting all PRs merged between #{merged_after_date} -  #{merged_before_date}")
  search_results = []
  Retriable.retriable do
    search_results = @client.search_issues("org:#{org_name} is:pr is:merged closed:#{merged_after_date}..#{merged_before_date}")
  end
rescue => e
  logger.error('Unable to search for merged PRs')
  logger.error(e.message)
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

  begin
    branch_protected = true
    Retriable.retriable do
      branch_protected = @client.branch(full_repo_name, pr_metadata.base.ref).protected
    end
  rescue Octokit::NotFound => e
    logger.info("Branch '#{pr_metadata.base.ref}' no longer exists for '#{pr_name}'. Skipping.")
    next
  end

  unless branch_protected
    logger.info("Skipping '#{pr_name}' because #{pr_metadata.base.ref} is not a protected branch.")
    next
  end

  begin
    branch_protections = nil
    Retriable.retriable do
      branch_protections = @client.branch_protection(full_repo_name, pr_metadata.base.ref, { accept: Octokit::Preview::PREVIEW_TYPES[:branch_protection] })
    end
  rescue => e
    logger.error("Unable to get branch protections summary for '#{pr_name}': #{e.message}")
    next
  end

  begin
    required_approval_count = 0
    Retriable.retriable do
      required_approval_count = branch_protections.required_pull_request_reviews.required_approving_review_count
    end
  rescue NoMethodError => e
    logger.warn("Unable to get required approval count for '#{pr_name}'. Assuming the required approval count is 0.")
  end

  logger.debug("PR '#{pr_name}' was merged by #{pr_metadata.merged_by.login}")

  begin
    reviews = []
    Retriable.retriable do
      reviews = @client.pull_request_reviews(full_repo_name, pr.number)
    end
  rescue => e
    logger.error("Unable to get pull request reviews for '#{pr_name}': #{e.message}")
    next
  end

  approval_count = count_approved_reviews(reviews)
  logger.info("The required number of approvers for '#{pr_name}' merged by #{pr_metadata.merged_by.login} was not met! (Approvals found: #{approval_count}/#{required_approval_count}) #{pr_metadata.html_url}") if approval_count < required_approval_count
end
