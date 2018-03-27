require 'net/http'
require 'uri'
require 'json'

module ApiRequest
  TOKEN = ENV["GITHUB_WEBSITE_TOKEN"].freeze

  def request_data(graphql_query)
    uri = URI.parse("https://api.github.com/graphql")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "bearer #{TOKEN}"
    request.body = JSON.dump({ query: graphql_query })

    response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: true }) do |http|
      http.request(request)
    end

    raise 'somethings not right with github api' if response.code.to_i >= 300

    JSON.parse(response.body)
  end
end

class GetOrganizations
  include ApiRequest

  QUERY = "
    query { 
      viewer { 
        organizations(first: 100){
          edges{
            node{
              id
              login
              name
            }
          }
        }
      }
    }
  ".freeze

  def all_organizations
    data = request_data(QUERY)
    organizations = data["data"]["viewer"]["organizations"]["edges"].map { |node| node["node"] }
    organizations.map { |organization| organization["login"] }
  end

  # def print_and_ask
  #   data = request_data(QUERY)
  #   organizations = data["data"]["viewer"]["organizations"]["edges"].map { |node| node["node"] }
  #   organizations.each_with_index do |organization, i|
  #     puts "#{i+1} - #{organization['login']}"
  #   end
  #   print "Enter index: "
  #   i = gets.strip.to_i - 1
  #   organizations[i]["login"]
  # end
end

class GetWebsitesFromFollowers
  include ApiRequest

  QUERY = "
    query { 
      viewer { 
        followers(first: 100){
          edges{
            node{
              id
              login
              name
              websiteUrl
            }
          }
        }
      }
    }
  ".freeze

  def print_websites
    data = request_data(QUERY)
    puts "Followers"
    puts "=" * 50
    members = data["data"]["viewer"]["followers"]["edges"].map { |node| node["node"] }
    members.each do |member|
      websiteUrl = member["websiteUrl"]
      if websiteUrl.to_s.length > 0
        puts "#{member['login']} - #{websiteUrl}"
      end
    end
  end
end

class GetWebsitesFromFollowing
  include ApiRequest

  QUERY = "
    query { 
      viewer { 
        following(first: 100){
          edges{
            node{
              id
              login
              name
              websiteUrl
            }
          }
        }
      }
    }
  ".freeze

  def print_websites
    data = request_data(QUERY)
    puts "Following"
    puts "=" * 50
    members = data["data"]["viewer"]["following"]["edges"].map { |node| node["node"] }
    members.each do |member|
      websiteUrl = member["websiteUrl"]
      if websiteUrl.to_s.length > 0
        puts "#{member['login']} - #{websiteUrl}"
      end
    end
  end
end

class GetWebsitesFromOrganization
  include ApiRequest

  QUERY = "
    query { 
      viewer { 
        organization(login: \"[ORG]\"){
          id
          websiteUrl
          login
          name
          url
          avatarUrl
          members(first: 100){
            edges{
              node{
                id
                websiteUrl
                login
                name
                url
                avatarUrl
              }
            }
          }
        }
      }
    }
  ".freeze

  attr_reader :organization_login

  def initialize(organization_login)
    @organization_login = organization_login
  end

  def print_websites
    data = request_data(QUERY.sub("[ORG]", organization_login))
    organization = data["data"]["viewer"]["organization"]
    puts "Organization: #{organization['login']}"
    puts "=" * 50
    members = organization["members"]["edges"].map { |node| node["node"] }
    members.each do |member|
      websiteUrl = member["websiteUrl"]
      if websiteUrl.to_s.length > 0
        puts "#{member['login']} - #{websiteUrl}"
      end
    end
  end
end

class GithubWebsites
  class << self
    def run
      GetWebsitesFromFollowing.new.print_websites
      puts
      GetWebsitesFromFollowers.new.print_websites
      puts
      organizations = GetOrganizations.new.all_organizations
      organizations.each do |organization|
        GetWebsitesFromOrganization.new(organization).print_websites
        puts
      end
    end
  end
end

GithubWebsites.run