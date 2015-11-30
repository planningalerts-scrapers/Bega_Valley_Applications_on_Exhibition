#!/usr/bin/env ruby
require 'scraperwiki'
require 'mechanize'

def strip_tags( str )
  str.gsub("</li>", "").gsub("</strong>", "").gsub("DA No.:&nbsp; ", "").gsub("&amp;","and")
end
def strip_titles( str )
  str.gsub("Description of Land: ", "").gsub("Description of Proposal: ", "")
end
def month_text_to_num(month_text)
  if month_text["anuary"] then return "01" end
  if month_text["ebuary"] then return "02" end
  if month_text["arch"] then return "03" end
  if month_text["pril"] then return "04" end
  if month_text["ay"] then return "05" end
  if month_text["une"] then return "06" end
  if month_text["uly"] then return "07" end
  if month_text["ugust"] then return "08" end
  if month_text["eptember"] then return "09" end
  if month_text["ctober"] then return "10" end
  if month_text["ovember"] then return "11" end
  if month_text["ecember"] then return "12" end
end
def find_on_notice_to(page) # text: "If you would like to comment on the proposal please write to us before"
  magic_string1 = "comment on the proposal"
  magic_string2 = "write to us before"
  lines = page.split("\n")
  on_notice_line = ""
  year = ""
  dday = ""
  month = ""
  lines.each do |line|
    if line[magic_string1] && line[magic_string2] then
      partial_cut = line[/before(.*)\./]
      on_notice_raw = partial_cut[7,partial_cut.length-8]
      year = on_notice_raw[on_notice_raw.length-4,on_notice_raw.length]
      month_text = on_notice_raw[2,on_notice_raw.length-7]
      month = month_text_to_num(month_text)
      dday = on_notice_raw[0,2].chomp(" ").rjust(2,"0")
    end
  end
  return "#{year}-#{month}-#{dday}"
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
	on_notice_to = find_on_notice_to(proposal_page.body)
	puts "To: #{on_notice_to}"
	record = {
		'council_reference' => council_reference,
		'address' => address,
		'description' => description,
		'info_url' => info_url,
		'comment_url' => comment_url,
		'date_scraped' => date_scraped,
		'on_notice_to' => on_notice_to
	}
	if (ScraperWiki.select("* from data where `council_reference` LIKE '#{record['council_reference']}'").empty? rescue true)
	  ScraperWiki.save_sqlite(['council_reference'], record)
      puts "Storing: #{record['council_reference']}"
	else
	  puts "Skipping already saved record " + record['council_reference']
	end

  end
end



