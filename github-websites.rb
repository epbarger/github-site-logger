require 'net/http'
require 'uri'
require 'json'
require 'pry'

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

    raise 'somethings fucky' if response.code.to_i >= 300

    JSON.parse(response.body)
  end
end

class GetWebsitesFromFollowers
  include ApiRequest

  QUERY = "
    query { 
      viewer { 
        followers(first: 100){
          edges{
            node{
              websiteUrl
              login
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
    puts
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
              websiteUrl
              login
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
    puts
  end
end

class GetWebsitesFromOrganizations
  include ApiRequest

  QUERY = "
    query { 
      viewer { 
        organizations(first: 100){
          edges{
            node{
              login
              members(first: 100){
                edges{
                  node{
                    websiteUrl
                    login
                  }
                }
              }
            }
          }
        }
      }
    }
  ".freeze

  def print_websites
    data = request_data(QUERY)
    organizations = data["data"]["viewer"]["organizations"]["edges"].map { |node| node["node"] }
    organizations.each do |organization|
      puts "Organization: #{organization['login']}"
      puts "=" * 50
      members = organization["members"]["edges"].map { |node| node["node"] }
      members.each do |member|
        websiteUrl = member["websiteUrl"]
        if websiteUrl.to_s.length > 0
          puts "#{member['login']} - #{websiteUrl}"
        end
      end
      puts
    end
    puts
  end
end

class GithubWebsites
  class << self
    def run
      GetWebsitesFromFollowing.new.print_websites
      GetWebsitesFromFollowers.new.print_websites
      GetWebsitesFromOrganizations.new.print_websites
    end
  end
end

GithubWebsites.run