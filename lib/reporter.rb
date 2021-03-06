class Reporter
  CSS = <<-EOCSS
   #total {
     width: 25%;
     float:right;
     padding-left: 50px;
   }
   table {
      border:1px solid black;
      border-collapse:collapse;
    }

    table thead {
      background-color:black;
      color:white;
    }

    tr {
      padding:0;
      margin:0;
      page-break-inside: avoid;
    }

    tr.week th {
      padding-top:30px;
      padding-bottom:10px;
    }

    tr.pause td {
      color:grey;
      font-size:80%;
    }


    td, th {
      margin:0;
      padding:4px;
      border:1px solid black;
      page-break-inside: avoid;
    }

    tr.double td {
      background-color:grey;
      color:red;
    }

    td.red {
      font-weight:bold;
      color: red;
    }

    tr td, tr th {
      page-break-inside: avoid;
    }

    tr.pauze td {
      color: grey;
      font-size:10px;
    }

    th.day   { width:200px; }
    th.date  { width:200px; }
    th.start { width:25em; }
    th.end   { width:25em; }
    th.dur   { width:25em; }
    th.title { width:80em; }
  EOCSS

  def self.from_events(week_from, week_until, events, hours_per_week)
    # Group into weeks
    raw_weeks = events.group_by { |evt| [evt.start_time.cwyear, evt.start_time.cweek] }

    # And convert into nice DS.
    weeks = {}
    Week.all_between(week_from, week_until).each do |week|
      weeks[week] = raw_weeks[[week.year, week.number]] || []
    end

    Reporter.new(weeks, hours_per_week)
  end

  def initialize weeks, hours_per_week
    @weeks = weeks
    @hours_per_week = hours_per_week
  end

  def print(file)
    File.open(file, "w") do |report|
      report.puts "<html>"
      report.puts "<head><style>#{CSS}</style></head>"
      report.puts "<body>"
      report.puts "The table of <a href='#holidays'>holidays</a> is at the bottom of this page"
      print_overview(report)
      print_by_week(report)
      print_holidays(report)
      report.puts "</body>"
      report.puts "</html>"
    end
  end

protected

  def print_overview report
    work_per_week     = Duration.new(@hours_per_week * 60 * 60)
    total_should_work = Duration.new(0)
    total_worked      = Duration.new(0)
    cumulative_diff   = Duration.new(0)

    report.puts "<div id='total'>"
    report.puts "<h1>Overview</h1>"
    report.puts "<table>"
    report.puts "<tr>"
    report.puts " <th>Year</th>"
    report.puts " <th>Week</th>"
    report.puts " <th>Should</th>"
    report.puts " <th>Did</th>"
    report.puts " <th>Diff</th>"
    report.puts " <th>Cum. Diff</th>"
    report.puts "</tr>"

    @weeks.each do |week, events|
      worked_in_week = sum_event_durations(events)
      cumulative_diff = cumulative_diff + worked_in_week - work_per_week

      total_should_work += work_per_week
      total_worked += worked_in_week
      report.puts "<tr>"
      report.puts " <td>#{week.year}</td>"
      report.puts " <td>#{week.number}</td>"
      report.puts " <td>#{work_per_week}</td>"
      report.puts " <td>#{worked_in_week}</td>"
      report.puts " <td>#{worked_in_week - work_per_week}</td>"
      report.puts " <td>#{cumulative_diff}</td>"
      report.puts " <td><a href='##{anchor_for(week)}'>Details</a></td>"
      report.puts "</tr>"
    end

    report.puts " <th colspan='2'>TOTAL</th>"
    report.puts " <th>#{total_should_work}</th>"
    report.puts " <th>#{total_worked}</th>"
    diff = total_worked - total_should_work
    report.puts " <th>%s (%0.5s dagen)</th>" % [diff, diff.days_fraction]

    report.puts "</table>"
    report.puts "</div>"
  end

  def print_by_week report
    report.puts "<h1>Week by week</h1>"
    @weeks.each do |week, events|
      print_week(report, week, events)
    end
  end

  def print_week report, week, events
    report.puts "<h2 id='#{anchor_for(week)}'>#{week.year}-#{week.number}</h2>"
    report.puts "<table>"
    report.puts "<tr>"
    report.puts " <th class='day'>Day</th>"
    report.puts " <th class='date'>Date</th>"
    report.puts " <th class='start'>Start</th>"
    report.puts " <th class='end'>End</th>"
    report.puts " <th class='dur'>Dur.</th>"
    report.puts " <th class='title'>Title</th>"
    report.puts "</tr>"

    events.each do |event|
      report.puts "<tr class='#{event.title.downcase.split(' ').first}'>"
      report.puts " <td>#{event.start_time.strftime("%A")}</td>"
      report.puts " <td>#{event.start_time.strftime("%Y-%m-%d")}</td>"
      report.puts " <td>#{event.start_time.strftime("%H:%M")}</td>"
      report.puts " <td>#{event.end_time.strftime("%H:%M")}</td>"
      report.puts " <td>#{event.duration.to_s}</td>"
      report.puts " <td>#{event.title}</td>"

      report.puts "</tr>"
    end

    total_duration = sum_event_durations(events)

    report.puts "<tr>"
    report.puts " <th colspan='4'>Totaal</td>"
    report.puts " <td colspan='2'>#{total_duration.to_s}</td>"
    report.puts "</tr>"

    report.puts "</table>"
  end

  def print_holidays(report)
    all_events = @weeks.values.flatten
    holiday_events = all_events.select { |event| event.type == :holiday }
    report.puts "<h1 id='holidays'>Holidays</h1>"
    report.puts "<table>"
    report.puts "<tr>"
    report.puts " <th>Year</th>"
    report.puts " <th>Week</th>"
    report.puts " <th>Day</th>"
    report.puts " <th>Date</th>"
    report.puts " <th>Start</th>"
    report.puts " <th>End</th>"
    report.puts " <th>Dur.</th>"
    report.puts " <th>Title</th>"
    report.puts "</tr>"

    holiday_events.each do |event|
      report.puts "<tr class='#{event.title.downcase.split(' ').first}'>"
      report.puts " <td>#{event.start_time.cwyear}</td>"
      report.puts " <td>#{event.start_time.cweek}</td>"
      report.puts " <td>#{event.start_time.strftime("%A")}</td>"
      report.puts " <td>#{event.start_time.strftime("%Y-%m-%d")}</td>"
      report.puts " <td>#{event.start_time.strftime("%H:%M")}</td>"
      report.puts " <td>#{event.end_time.strftime("%H:%M")}</td>"
      report.puts " <td>#{event.duration.to_s}</td>"
      report.puts " <td>#{event.title}</td>"
      report.puts "</tr>"
    end

    total_duration = sum_event_durations(holiday_events)
    report.puts "<tr>"
    report.puts " <th colspan='7'>Total hours</td>"
    report.puts " <th colspan='2'>%s (%0.5s days)</td>" % [total_duration, total_duration.days_fraction]
    report.puts "</tr>"

    report.puts "</table>"
  end

  def sum_event_durations(events)
    events.collect { |event| event.duration }.inject(:+) || Duration.new(0)
  end

  def anchor_for(week)
    "#{week.year}-#{week.number}"
  end
end
