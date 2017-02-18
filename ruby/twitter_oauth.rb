require 'oauth'
require 'json'
require 'fileutils'

$consumer_key = ""
$consumer_secret = ""
$oauth_token = ""
$oauth_token_secret = ""

$access_token = nil

SLEEP_MIN = 60
SLEEP_MAX = 90


def readTokens()
  f = File.new("tokens.txt", "r")
  $consumer_key = f.gets().chomp()
  $consumer_secret = f.gets().chomp()
  $oauth_token = f.gets().chomp()
  $oauth_token_secret = f.gets().chomp()
  f.close

#  puts $consumer_key
#  puts $consumer_secret
#  puts $oauth_token
#  puts $oauth_token_secret
  
end

# Exchange your oauth_token and oauth_token_secret for an AccessToken instance.
def prepare_access_token(oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new($consumer_key, $consumer_secret, { :site => "https://api.twitter.com", :scheme => :header })
     
    # now create the access token object from passed values
    token_hash = { :oauth_token => oauth_token, :oauth_token_secret => oauth_token_secret }
    $access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
 
end


def displayHomeTweets() 
  # use the access token as an agent to get the home timeline
  response = $access_token.request(:get, "https://api.twitter.com/1.1/statuses/home_timeline.json")

  puts response
  #puts response["followers_count"]

  i = 0
  tweets = JSON.parse(response.body)
  tweets.map do | tweet |
    if (i < 10)
#      puts i.to_s + ": User: " + tweet["user"]["name"] + " " + "Tweet: " + tweet["text"]
      puts " " + "Tweet: " + tweet["text"]
    end
  i += 1
  end
end



def followUser(username) 
  #Follow user
#  username = ARGV[0]
  puts "Follwing #{username}"

  response = $access_token.request(:post, "https://api.twitter.com/1.1/friendships/create.json?screen_name=#{username}&follow=true")
  puts response

end

def followGoodList()
  arrayGoodList = Array.new()
  File.open("goodlist.txt").each do |line|
    arrayGoodList << line.chomp()
  end

  arrayGoodList.each { |username|

    puts "Follwing #{username}"

    response = $access_token.request(:post, "https://api.twitter.com/1.1/friendships/create.json?screen_name=#{username}&follow=true")
    puts response
    iSleep = SLEEP_MIN + rand(SLEEP_MAX - SLEEP_MIN)
    puts "Sleeping for #{iSleep} seconds"
    sleep(iSleep)
  }

  strArchiveFile = "goodlist" + Time.now.strftime("%Y%m%d_%H%M%S") + ".txt"
  puts "Moving goodlist.txt to #{strArchiveFile}"
  FileUtils.mv('goodlist.txt', strArchiveFile) 
end

def makeGoodList(username)

  puts "Making goodlist.txt for #{username}"

  # use the access token as an agent to get the home timeline
  response = $access_token.request(:get, "https://api.twitter.com/1.1/followers/ids.json?cursor=-1&screen_name=#{username}&count=200")

  puts response
  #puts response["followers_count"]

  f = File.new("goodlist.txt", "w")

#  puts "RESULT: " + JSON.parse(response.body)
  users = JSON.parse(response.body)
#  puts users["next_cursor"]
  puts users["ids"]
  users["ids"].each do |id|
    puts "ID: #{id}"
    f.puts "#{id}"
  end

#  users.map do | user |
#       puts "#{i}: " + user["id"]
#      puts " " + "User: " + user["screen_name"]
#    puts user
#    puts user['ids']
#  end

  f.close()

end

def followGoodListByID()
  arrayGoodList = Array.new()
  File.open("goodlist.txt").each do |line|
    arrayGoodList << line.chomp()
  end

  arrayGoodList.each { |userid|

    puts "Follwing #{userid}"

    response = $access_token.request(:post, "https://api.twitter.com/1.1/friendships/create.json?user_id=#{userid}&follow=true")
    puts response
    iSleep = SLEEP_MIN + rand(SLEEP_MAX - SLEEP_MIN)
    puts "Sleeping for #{iSleep} seconds"
    sleep(iSleep)
  }

  strArchiveFile = "goodlist" + Time.now.strftime("%Y%m%d_%H%M%S") + ".txt"
  puts "Moving goodlist.txt to #{strArchiveFile}"
  FileUtils.mv('goodlist.txt', strArchiveFile) 
end



def displayUsage() 
    puts "Usage: ruby twitter_oauth.rb <command> <options>"
    puts "Commands: hometweets - list tweets in your timeline"
    puts "          follow <username> - follows the specified user"
    puts "          followgoodlist    - follows all IDs in goodlist.txt file"
    puts "          followgoodlistusername  - follows all handles in goodlist.txt file"
    puts "          makegoodlist <username>  - creates goodlist.txt file using "
    puts "            followers of the specified user"

end


def main()
  readTokens()
 
  # Exchange our oauth_token and oauth_token secret for the AccessToken instance.
  prepare_access_token($oauth_token, $oauth_token_secret)

  if (ARGV.count == 0) 
    displayUsage()
  elsif (ARGV[0].upcase == "HOMETWEETS") 
    displayHomeTweets() 
  elsif (ARGV[0].upcase == "FOLLOW") 
    followUser(ARGV[1]) 
  elsif (ARGV[0].upcase == "FOLLOWGOODLIST") 
      followGoodListByID()
  elsif (ARGV[0].upcase == "FOLLOWGOODLISTUSERNAME") 
      followGoodList()
  elsif (ARGV[0].upcase == "MAKEGOODLIST") 
    makeGoodList(ARGV[1])
  else 
    puts "Invalid option"
    displayUsage()
  end



end

main()

