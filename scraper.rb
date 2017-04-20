#!/usr/bin/env ruby
Bundler.require

module ATDIS
  require "open-uri"

  class Model
    def self.read_url(url)
      r = read_json(RestClient::Resource.new(url.to_s, timeout: 300).get.to_str)
      r.url = url.to_s
      r
    end
  end
end

url = "http://datracker.begavalley.nsw.gov.au/ATDIS/1.0/"

ATDISPlanningAlertsFeed.save(url)