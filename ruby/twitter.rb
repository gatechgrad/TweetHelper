require 'net/http'

#strContents = Net::HTTP.get('google.com', '/index.html')
#puts "Google contents: #{strContents}"


#strContents = Net::HTTP.get('twitter.com', '/index.html')
#puts "Twitter contents: #{strContents}"


#uri = URI('http://levidsmith.com')
#puts Net::HTTP.get(uri)

uri = URI('https://api.twitter.com/1.1/search/tweets.json?q=%40gatechgrad')
puts Net::HTTP.get(uri)
