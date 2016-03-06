require "active_support"
require "active_support/all"

require "./send_emails"

require "redis"
$REDIS = Redis.new

if $REDIS.get "ran_recently"
  puts "Nothing to do, last ran at #{$REDIS.get("last_ran")}"
  exit
end

# People are stored as a big ol' string in redis
people_txt = $REDIS.get "people"
people = people_txt.strip.split("\n").map do |line|
  pieces = line.split " "

  [pieces[0...-1].join(" "), pieces.last]
end

previous_people_raw = $REDIS.get('people_arr')
previous_people = nil
previous_people = JSON.parse(previous_people_raw) if previous_people_raw

def good_pairings(people, previous_people)
  return false if people == previous_people
  true
end

while true do
  people.shuffle!

  break if good_pairings(people, previous_people)
end

loner = people.pop if people.size % 2 == 1

pairings = people.each_slice(2).map do |a, b|
  [a, b]
end

# Add third wheel if we have a loner
if loner
  pairings.sample.push loner
end

pairings.each_with_index do |pairing, index|
  puts "#{index}: #{pairing.inspect}"
end

$REDIS.set "people_arr", people.inspect
$REDIS.set "pairings", pairings.inspect

pairings.each_with_index do |pairing, index|
  email_addresses = pairing.map(&:last)

  print email_addresses.inspect

  # Assuming being sent out on Friday morning
  start_time = 5.days.from_now.at_noon

  send_emails pairing

  puts " DONE!"
end

$REDIS.set "last_ran", Time.now
$REDIS.set "ran_recently", true
$REDIS.expire "ran_recently", (1.week.from_now - Time.now).to_i - 7200
