require "sqlite3"
require "date"
require "time"
require "gruff" # NOTE: requires rmagick

# Print all files in the /hadata directory for debugging purposes
puts "Files in /hadata:"
puts Dir.entries("/hadata")

db = SQLite3::Database.new("/hadata/home-assistant_v2.db")

query = <<~SQL
WITH EventsWithDiffs AS (
  SELECT
    e.*,
    ed.*,
    LAG(time_fired_ts) OVER (ORDER BY time_fired_ts) AS prev_time_fired_ts
  FROM events e
  JOIN event_data ed ON e.data_id = ed.data_id
  WHERE shared_data LIKE '%current_orientation%'
),
EventsWithGroups AS (
  SELECT
    *,
    SUM(CASE
          WHEN (time_fired_ts - COALESCE(prev_time_fired_ts, 0)) > 500 THEN 1
          ELSE 0
        END) OVER (ORDER BY time_fired_ts) AS event_group
  FROM EventsWithDiffs
)

SELECT time_fired_ts
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY event_group ORDER BY time_fired_ts) AS rn
  FROM EventsWithGroups
)
WHERE rn = 1;
SQL

# The above query returns timestamps (UNIX format, float) of events. We define an event as a change in the orientation with a 500 second cooldown.
# We want to then turn these timestamps into a chart that shows the number of events that occurred in each day.

timestamps = []

db.execute(query) do |row|
  raw_timestamp = row[0]
  timestamps << Time.at(raw_timestamp)
end

timestamps_by_day = timestamps.group_by do |timestamp|
  timestamp.to_date
end

chart_data = timestamps_by_day.map do |date, timestamps|
  [date, timestamps.size]
end

# Now generate the chart using gruff
g = Gruff::StackedBar.new
g.title = "Litterbox events per day"


# Setup labels for the x-axis with formatted dates
g.labels = chart_data.map { |date, _| [chart_data.index([date, _]), date.strftime("%m-%d")] }.to_h
# Setup the data for plotting
g.data("Events", chart_data.map { |_, count| count })
# Enabling marker count for better readability on the x-axis
g.marker_count = chart_data.size
# Enable data labels to show values on the graph
g.show_labels_for_bar_values = true
# Writing the output to a file that includes the date
g.write("/output/litterbox_data_#{Date.today}.png")

puts "Chart generated successfully! Check /output for the image."
puts "/output/litterbox_data_#{Date.today}.png"
