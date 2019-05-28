#!/usr/bin/env ruby
Bundler.require

url = "http://datracker.begavalley.nsw.gov.au/ATDIS/1.0/"

ATDISPlanningAlertsFeed.save(url, "Sydney")
