require 'net/http'
require 'json'
require 'date'

canada_population = 38008005

endpoint = "/reports?date=#{Date.today}"

uri = URI.parse("https://api.covid19tracker.ca#{endpoint}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

req = Net::HTTP::Get.new(uri.request_uri)

response = http.request(req)
data = JSON.parse(response.body)
data = data["data"][0]

new_vax = data["change_vaccinations"]
total_vax = data["total_vaccinations"]
percent_vax = total_vax.to_f / canada_population * 100

remaining_vax = canada_population - total_vax
days_to_total_vax = remaining_vax.to_f/new_vax
days_to_total_vax = days_to_total_vax.ceil()
date_of_total_vax = Date.today + days_to_total_vax

puts("Today #{new_vax} people were vaccinated in Canada")
puts("Overall, #{total_vax} people have been vaccinated. This is #{'%.2f' % percent_vax}% of the population.")
puts("If Canada keeps vaccinating at the rate we did today, everyone will be vaccinated by #{date_of_total_vax}")