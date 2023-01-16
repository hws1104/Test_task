require 'httparty'
require 'nokogiri'
require 'open-uri'

url = "https://www.nasa.gov/press-release/nasa-industry-to-collaborate-on-space-communications-by-2025"
# url = "https://www.nasa.gov/press-release/us-vice-president-french-president-visit-nasa-headquarters/"
# url = "https://www.nasa.gov/press-release/nasa-s-stakeholder-collaborations-help-inform-moon-to-mars-planning"
html_doc = Nokogiri::HTML(URI.open(url))

str = html_doc.css('script').find { |e| e.text.include?('window.forcedRoute = ')}.text
str.slice!('window.forcedRoute = "')
str.slice!(-1)

response = HTTParty.get("https://www.nasa.gov/api/2#{str}")
source = JSON.parse(response.body)['_source']
data = {}
data[:title] = source['title']
data[:date] = source['promo-date-time'][0..9]
data[:release_no] = source['release-id']

body = source['body'].gsub /^$\n/, ''
doc = Nokogiri::HTML(body)
doc.css('.dnd-atom-wrapper').remove
data[:article] = doc.text[1..-7]

puts data