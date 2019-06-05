#!/usr/bin/env ruby
Bundler.require

ATDISPlanningAlertsFeed.save(
  "http://datracker.begavalley.nsw.gov.au/ATDIS/1.0/",
  "Sydney"
)
