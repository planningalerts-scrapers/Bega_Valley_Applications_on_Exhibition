#!/usr/bin/env ruby
require 'scraperwiki'
require 'mechanize'

def strip_tags(str)
  str.gsub("</li>", "").gsub("</strong>", "").gsub("DA No.:&nbsp; ", "").gsub("&amp;","and")
end
def strip_titles(str)
  str.gsub("Description of Land: ", "").gsub("Description of Proposal: ", "")
end
def clean_whitespace(str)
   if (! str.nil?) then
     str.gsub("\r "," ").gsub("\n"," ").gsub("\t"," ").gsub("\b"," ").squeeze(" ").strip
   end
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
def find_on_notice_to(page)
# searching for text: "If you would like to comment on the proposal please write to us before"
  magic_string1 = "comment on the proposal"
  magic_string2 = "write to us before"
  lines = page.split("\n")
  year = ""
  dday = ""
  month = ""
  lines.each do |line|
    if line[magic_string1] && line[magic_string2] then
      partial_cut = line[/before(.*)\./]
      on_notice_raw = partial_cut[7,partial_cut.length-8]
      year = on_notice_raw[on_notice_raw.length-4,on_notice_raw.length]
      month = month_text_to_num(on_notice_raw[2,on_notice_raw.length-7])
      dday = on_notice_raw[0,2].chomp(" ").rjust(2,"0")
    end
  end
  return "#{year}-#{month}-#{dday}"
end
def clean_address(raw_address)
  # messy... first regex cuts upto "DP:", then the second cuts after the first "-"
  return "#{raw_address[/(?<=DP:)(.*)/][/(?<=-)(.*)/]}, NSW"
end
def clean_alt_address(raw_address)
  trim1 = raw_address[/(?<=DP )(.*)/]
  if (trim1.nil?) then trim1 = raw_address[/(?<=SP )(.*)/] end #sometimes SP is used instead of DP
  trim2 = "#{trim1[/(?<=\ )(.*)/]}, NSW"
  if (trim2[0] == "&") then #strip second ref# if there
    trim2 = trim2[/(?<=\ )(.*)/]
    trim2 = trim2[/(?<=\ )(.*)/]
  end
  if(trim2.start_with?("Sec")) then #strip section#
    trim2 = trim2[/(?<=\ )(.*)/]
	  if(trim2[/^[0-9]+,/]) then #with optional space
		trim2 = trim2[/(?<=\ )(.*)/]
	  end
  end
  return trim2.strip
end

base_url = "http://www.begavalley.nsw.gov.au/page.asp?c=553"
alt_base_url = "http://www.begavalley.nsw.gov.au/cp_themes/default/page.asp?p=DOC-JDH-32-26-07"
agent = Mechanize.new
main_page = agent.get(base_url)
alt_main_page = agent.get(alt_base_url)
date_scraped = Date.today.to_s
comment_url = "mailto:council@begavalley.nsw.gov.au" # so not good

main_page.links.each do |link|
  if(link.text["Development Proposal"])
    proposal_page = agent.get(link.href)
    council_reference = strip_tags(proposal_page.body[/DA\ No(.*)/]).chomp.strip
    address = clean_address(strip_titles(strip_tags(proposal_page.body[/Description of Land(.*)/])).chomp.strip)
    description = strip_titles(strip_tags(proposal_page.body[/Description of Proposal(.*)/])).chomp.strip
	info_url = "http://www.begavalley.nsw.gov.au#{link.uri}"
	on_notice_to = find_on_notice_to(proposal_page.body)
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

alt_main_page.search("/html/body/div/div/div[2]/div[2]/div/p").each do |plan|
  plan_text = plan.text
  raw_council_reference = plan_text[/(Development)(.*)/]
  if (! raw_council_reference.nil?) then 
    council_reference = clean_whitespace(raw_council_reference[/[0-9]+.[0-9]+/])
    address = clean_alt_address(clean_whitespace(plan_text[/(?<=Property:\ )(.*)/]))
	description = clean_whitespace(plan_text[/(?<=Proposal:\ )(.*)/])
	if(description.nil?) then description = "not provided" end 
	info_url = alt_base_url
	
	record = {
		'council_reference' => council_reference,
		'address' => address,
		'description' => description,
		'info_url' => info_url,
		'comment_url' => comment_url,
		'date_scraped' => date_scraped,
	}
	if (ScraperWiki.select("* from data where `council_reference` LIKE '#{record['council_reference']}'").empty? rescue true)
	  ScraperWiki.save_sqlite(['council_reference'], record)
      puts "Storing: #{record['council_reference']}"
	else
	  puts "Skipping already saved record " + record['council_reference']
	end
  end
end
