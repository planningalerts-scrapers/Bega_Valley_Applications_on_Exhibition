#!/usr/bin/env ruby
# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful
require 'scraperwiki'
require 'mechanize'

def strip_tags( str )
  str.gsub("</li>", "").gsub("</strong>", "").gsub("DA No.:&nbsp; ", "").gsub("&amp;","and")
end
def strip_titles( str )
  str.gsub("Description of Land: ", "").gsub("Description of Proposal: ", "")
end

base_url = "http://www.begavalley.nsw.gov.au/page.asp?c=553"

agent = Mechanize.new
main_page = agent.get(base_url)
date_scraped = Date.today.to_s

main_page.links.each do |link|
  if(link.text["Development Proposal"])
    proposal_page = agent.get(link.href)
    council_reference = strip_tags(proposal_page.body[/DA\ No(.*)/]).chomp.strip
    address = strip_titles(strip_tags(proposal_page.body[/Description of Land(.*)/])).chomp.strip
    description = strip_titles(strip_tags(proposal_page.body[/Description of Proposal(.*)/])).chomp.strip
	info_url = "http://www.begavalley.nsw.gov.au#{link.uri}"
	comment_url = proposal_page.body["mailto:council@begavalley.nsw.gov.au"] # so not good

	record = {
		'council_reference' => council_reference,
		'address' => address,
		'description' => description,
		'info_url' => info_url,
		'comment_url' => comment_url,
		'date_scraped' => date_scraped
	}
	if (ScraperWiki.select("* from data where `council_reference` LIKE '#{record['council_reference']}'").empty? rescue true)
	  ScraperWiki.save_sqlite(['council_reference'], record)
      puts "Storing: #{record['council_reference']}"
	else
	  puts "Skipping already saved record " + record['council_reference']
	end

  end
end



