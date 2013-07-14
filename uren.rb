#!/usr/bin/env ruby
require_relative "lib/week"
require_relative "lib/event"
require_relative "lib/duration"
require_relative "lib/fetcher"
require_relative "lib/reporter"

week_from  = Week.new(2013, 1)
week_until = Week.new(2013, 35)
hours_per_week = 16

$stdout.sync = true

fetcher = Fetcher.new(week_from, week_until)
print "Fetching events..."
  raw_events = fetcher.fetch_all
puts "DONE"

print "Processing events..."
  # Select the events that are relevant
  raw_events.select! do |event|
    title = event.title.downcase
    (event.status == "confirmed" || event.status == "tentative") && \
    (title.include?("@home") || title.include?("aanwezig") || title == "vakantie")
  end

  # Remove duplicates in time & create pauses
  events = []
  raw_events.each do |event|
    if !events.include?(event)
      events << event
      if event.title.downcase == 'vakantie'
        event.type = :holiday
      elsif (event.duration.hours >= 4)
        pause_start = DateTime.commercial(event.start_time.cwyear, event.start_time.cweek, event.start_time.cwday, 12, 00)
        pause_end   = DateTime.commercial(event.start_time.cwyear, event.start_time.cweek, event.start_time.cwday, 12, 45)
        events << Event.new("pauze", "confirmed", pause_start, pause_end, :pause)
      end
    end
  end
puts "DONE"

print "Writing report..."
  Reporter.from_events(week_from, week_until, events, hours_per_week).print("report.html")
puts "DONE. Written to ./report.html"
