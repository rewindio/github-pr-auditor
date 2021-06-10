#!/usr/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'octokit'
require 'dotenv'

logger = Logger.new($stdout)
logger.level = Logger::INFO
logger.info('Starting repo manager...')

# Configuration
Dotenv.parse('.env.local', '.env')
Dotenv.require_keys('GITHUB_API_TOKEN', 'GITHUB_ORG_NAME')
org_name = ENV['GITHUB_ORG_NAME']

@client = Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'], per_page: 100, auto_paginate: true)

admin_team = @client.team_by_name(org_name, ENV['GITHUB_ADMIN_TEAM'])

@client.organization_repositories(org_name).each do |repo|
  next if repo.archived?

  begin
    logger.info("Ensuring that #{admin_team.name} has admin access to #{org_name}/#{repo.name}")
    @client.add_team_repository(admin_team.id, "#{org_name}/#{repo.name}", permission: 'admin')
  rescue => e
    logger.error("Unable to manage repo #{repo}}': #{e.message}")
  end
end
