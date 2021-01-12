require 'net/http'
require 'json'
require 'time'
require 'twitter'

class NoDataError < StandardError
end

def get_data(t = Time.now)

  if t.zone == "UTC"
    puts("time in UTC, converting")
    t = t.localtime("-08:00")
  else 
    puts("time local, we're all good")
  end

  date = t.strftime("%Y-%m-%d")

  # using the reports api
  endpoint = "/reports?date=#{date}"

  request_uri = "https://api.covid19tracker.ca#{endpoint}"
  puts("requesting data from: " + request_uri)

  uri = URI.parse(request_uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  puts("requesting data")
  req = Net::HTTP::Get.new(uri.request_uri)

  response = http.request(req)

  puts("data received (#{response.body.length} characters)")
  
  data = JSON.parse(response.body)
  data = data["data"][0]

  begin
    new_vax = data["change_vaccinations"]
    total_vax = data["total_vaccinations"]
  rescue NoMethodError
    raise(NoDataError, "no data available for today")
  end

  puts("data parsed: #{new_vax} new vaccinations, #{total_vax} total vaccinations")

  return new_vax, total_vax

end

def generate_tweet()
  canada_population = 38008005

  new_vax, total_vax = get_data()

  percent_vax = total_vax.to_f / canada_population * 100

  remaining_vax = canada_population - total_vax
  days_to_total_vax = remaining_vax.to_f/new_vax
  days_to_total_vax = days_to_total_vax.ceil()
  date_of_total_vax = Date.today + days_to_total_vax 

  day_endings = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th",
                 "th", "th", "th", "th", "th", "th", "th", "th", "th", "th",
                 "th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th",
                 "th", "st"]

  day = date_of_total_vax.mday.to_s + day_endings[date_of_total_vax.mday]
  date_fmt = date_of_total_vax.strftime("%B #{day} %Y")

  tweet_string = "Today #{new_vax} people were vaccinated in Canada. If Canada keeps vaccinating at the rate we did today, everyone will be vaccinated by #{date_fmt}."

  puts("generated tweet string:")
  puts("\t" + tweet_string)

  return tweet_string
end

def get_twitter_client()

  client = Twitter::REST::Client.new do |config|

    if not (ENV['TWITTER_API_KEY'] and ENV['TWITTER_API_SECRET'] and ENV['TWITTER_ACCESS_TOKEN'] and ENV['TWITTER_ACCESS_TOKEN_SECRET'])
      raise("environment variables not set!")
    end


    config.consumer_key =           ENV['TWITTER_API_KEY']
    config.consumer_secret =        ENV['TWITTER_API_SECRET']
    config.access_token =           ENV['TWITTER_ACCESS_TOKEN']
    config.access_token_secret =    ENV['TWITTER_ACCESS_TOKEN_SECRET']
  end
  return client
end

def send_tweet(twitter_client, tweet_string)
  twitter_client.update(tweet_string)
end

def get_heroku_client()
    client = PlatformAPI.connect_oauth(ENV['HEROKU_API_KEY'])
    return client
end

puts("generating tweet")
begin
  tw_str = generate_tweet()
rescue NoDataError => e
  puts e.message
  return
end

puts("getting twitter client")

client = get_twitter_client()

puts("Tweeting")

send_tweet(client, tw_str)

