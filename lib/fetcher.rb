require "open-uri"
require "nokogiri"

class Fetcher
  def self.calendar_url
    @@url ||= File.read("calendar_url.txt").chomp
  end

  def initialize(week_from, week_until)
    @from = week_from
    @until = week_until
  end

  def fetch_all
    events = []
    doc = retrieve_xml_doc

    doc.root.children.css("entry").each do |entry|
      events += parse_events(entry)
    end

    events.sort_by { |event| event.start_time }
  end

  protected
  def parse_events(entry)
    events = []
    title = entry.css("title").text
    status = entry.css("gd|eventStatus").first["value"].split(".").last

    entry.css("gd|when").each do |whn|
      start_time = whn["startTime"]
      end_time   = whn["endTime"]

      if start_time != nil && end_time != nil
        events << Event.new(title, status, start_time, end_time)
      end
    end

    events
  end

  def retrieve_xml_doc
    start_date = @from.monday
    end_date = @until.sunday
    url = Fetcher.calendar_url + "?" + \
          "orderby=starttime&" + \
          "max-results=100000000&" + \
          "recurrence-expansion-start=#{start_date}&" + \
          "start-min=#{start_date}&" + \
          "start-max=#{end_date}"
    raw_xml = open(url).read

    Nokogiri.parse(raw_xml)
  end
end
