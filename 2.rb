require 'google/apis/drive_v3'
require 'pdf/reader'
require 'httparty'


def str_to_date(str)
  pat = "%m/%d/%y"
  pat = "%m/%d/%Y" if str.length > 7
  Date.strptime(str, pat).strftime("%F")
end

def read_data(filename)
  res = {}
  pdf = PDF::Reader.new("pdfs/#{filename}")
  text = pdf.page(1).text
  m = text.match /In the Supreme Court of the (?<state>[\w ]+)/
  res[:state] = m.nil?? "" : m[:state]

  m = text.match /Date[\w ]*: (?<date>[\d\/]+)/
  res[:date] = m.nil?? "" : str_to_date(m[:date])

  m = text.match /(?<amount>\$[\d\,]+.?\d*)/
  res[:amount] = m.nil?? "" : m[:amount]

  if text.include? "Petitioner,"
    m = text.match /\n{2,} *(?<petitioner>.+),/
    res[:petitioner] = m.nil?? "" : m[:petitioner]
  else
    res[:petitioner] = ""
  end

  res
end

def access_token()
  refresh_token = "1//04dRoDsMrKTwSCgYIARAAGAQSNwF-L9IrQ-k-FwS2Sg8oW0LwXX0vrHk5VP1Te4pKcqbOhKbdC8K8nS3TRcGyxWpIlt8XwDxSZwA"
  data = { refresh_token: refresh_token,
           client_id: '732848243306-ieaerbnavkjt1bgnbahejd3rrpr8u38k.apps.googleusercontent.com',
           client_secret: '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',
           grant_type: 'refresh_token' }
  url = 'https://accounts.google.com/o/oauth2/token'
  resp = HTTParty.post(url, body: data.to_json, headers: { 'Content-Type' => 'application/json' })
  resp['access_token']
end

drive = Google::Apis::DriveV3::DriveService.new
drive.authorization = access_token
# puts access_token

results = drive.list_files(q: "mimeType='application/pdf' and trashed = false and parents in '1v8kAzirygnGsKm4X0eX_OhNgFPw865aQ'")

directory_name = "pdfs"
Dir.mkdir(directory_name) unless File.exists?(directory_name)

data = []

puts "Total PDF file counts: #{results.files.length}"

results.files.each do |file|
  puts file.name
  drive.get_file(file.id, download_dest: "pdfs/#{file.name}")
  data.push(read_data(file.name))
end

puts data


# Dir.foreach('pdfs').each do |fname|
#   next if (fname[0] == ".")
#   puts fname
#   puts read_data fname
#   puts ""
# end