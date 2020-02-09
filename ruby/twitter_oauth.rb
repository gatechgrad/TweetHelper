###
#
# TwitterOAuth (twitter_oauth.rb)
# 2017 Levi D. Smith - @GaTechGrad
#
###

require 'oauth'
require 'json'
require 'fileutils'
require 'date'

$consumer_key = ""
$consumer_secret = ""
$oauth_token = ""
$oauth_token_secret = ""

LOOKUP_SLEEP_INTERVAL = 61
REQUEST_SLEEP_INTERVAL = 10
$iSleepInterval = LOOKUP_SLEEP_INTERVAL


$access_token = nil

SLEEP_MIN = 60
SLEEP_MAX = 70

FOLLOWERS_LIMIT = 50
FOLLOW_RATIO_LIMIT = 200
LAST_ACTION_LIMIT = 5

USERS_PER_CURSOR_PAGE = 5000
GOOD_LIST_MAX = 500 
FOLLOW_LIST_MAX = 250 
USERS_PER_FRIEND_QUERY = 100 

MAX_PEOPLE_TO_FOLLOW = 250

TWITTER_FOLLOW_LIMIT = 5000
TWITTER_RATIO_LIMIT = 1.1 

INFINITY = 9999

ALLFOLLOWERS_FILENAME = "data/allfollowers.txt"
ALLFOLLOWING_FILENAME = "data/allfollowing.txt"
ALLFOLLOWERIDS_FILENAME = "data/allfollower_ids.txt"
ALLFOLLOWINGIDS_FILENAME = "data/allfollowing_ids.txt"
NOTFOLLOWBACKIDS_FILENAME = "data/notfollowback_ids.txt"
NOTFOLLOWBACKHTML_FILENAME = "data/notfollowback.html"
FOLLOW_QUERY_COUNT = 200

BADWORDS_FILENAME = "conf/badwords.txt"
NAUGHTYPEOPLE_FILENAME = "data/naughtypeople.html"
GOODLANGUAGE_FILENAME = "conf/goodlanguage.txt"

GOODLIST_FILENAME = "data/goodlist.txt"
FOLLOWLIST_ARCHIVE_PREFIX = "data/followlist"
FOLLOWLIST_ARCHIVE_SUFFIX = ".txt"
FOLLOWLIST_FILENAME = "data/followlist.txt"
PURGELIST_FILENAME = "data/purgelist.txt"
WHITELIST_FILENAME = "conf/whitelist.txt"
CHECKED_FILENAME = "data/checked.txt"

TOKENS_FILENAME = "conf/tokens.txt"

def readTokens()
  f = File.new(TOKENS_FILENAME, "r")
  $consumer_key = f.gets().chomp()
  $consumer_secret = f.gets().chomp()
  $oauth_token = f.gets().chomp()
  $oauth_token_secret = f.gets().chomp()
  f.close
end

# Code from Twitter developer examples
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



def deleteDirectMessages() 
  whiteListArray = Array.new()
  f = File.open(WHITELIST_FILENAME)
  f.each_line {|line|
    whiteListArray << line.upcase().chomp()
  }
  f.close()


  # use the access token as an agent to get the home timeline
  response = $access_token.request(:get, "https://api.twitter.com/1.1/direct_messages.json")

  puts response

  i = 0
  dms = JSON.parse(response.body)
  dms.each do | dm |
#    puts "#{i} Message: #{dm}"
    puts "#{i} screen_name #{dm["sender_screen_name"]}"
    puts "     text #{dm["text"]}"
    screen_name = dm["sender_screen_name"]
    if (whiteListArray.include?(screen_name.upcase()))
      puts "WHITELISTED, DON'T DELETE"
    else 
      id = dm["id"]
      puts "SPAM, DELETE DM ID #{id}"
      response1 = $access_token.request(:post, "https://api.twitter.com/1.1/direct_messages/destroy.json?id=#{id}")
      puts "Sleeping for 61"
      sleep(61)
    end

    i += 1
  end


end



def followUser(username) 
  #Follow user
  puts "Following #{username}"

  response = $access_token.request(:post, "https://api.twitter.com/1.1/friendships/create.json?screen_name=#{username}&follow=true")
  puts response

end

def followFollowList()
  if (File.file?(FOLLOWLIST_FILENAME)) 

    arrayFollowList = Array.new()

  
    File.open(FOLLOWLIST_FILENAME).each do |line|
      arrayFollowList << line.chomp()
    end

    if (!checkFollowerRatio(arrayFollowList.size))
      exit 
    end 

    arrayFollowList.each { |userid|

      puts "Following #{userid}"

      response = $access_token.request(:post, "https://api.twitter.com/1.1/friendships/create.json?user_id=#{userid}&follow=true")
      puts response

      #check response
      result = JSON.parse(response.body)
      if (result.class == Hash && !result["errors"].nil?)
        puts "ERROR with #{userid}.  Reached follow limit?"
        #Should clean up the followlist.txt file and archive here 
        puts "Need to manually archive followlist.txt with everyone who has been followed;  Put everyone else back in the followlist.txt file;  Unfollow some people and try again later"
        exit
      end


      iSleep = 61 
#    iSleep = SLEEP_MIN + rand(SLEEP_MAX - SLEEP_MIN)
      puts "Sleeping for #{iSleep} seconds"
      sleep(iSleep)
    }

    archiveFollowList()
  else
    puts "No #{FOLLOWLIST_FILENAME}.  Use MAKEFOLLOWLIST first"
  end

end

def followGoodList()
  arrayGoodList = Array.new()
  File.open(GOODLIST_FILENAME).each do |line|
    arrayGoodList << line.chomp()
  end

  arrayGoodList.each { |username|

    puts "Following #{username}"

    response = $access_token.request(:post, "https://api.twitter.com/1.1/friendships/create.json?screen_name=#{username}&follow=true")
    puts response
    iSleep = SLEEP_MIN + rand(SLEEP_MAX - SLEEP_MIN)
    puts "Sleeping for #{iSleep} seconds"
    sleep(iSleep)
  }

  archiveGoodList()

end

def unfollowPurgeList()

  if (File.file?(PURGELIST_FILENAME))

    arrayPurgeList = Array.new()

    File.open(PURGELIST_FILENAME).each do |line|
      arrayPurgeList << line.chomp()
    end

    arrayPurgeList.each { |user_id|

      puts "Unfollowing #{user_id}"

      response = $access_token.request(:post, "https://api.twitter.com/1.1/friendships/destroy.json?user_id=#{user_id}")
      puts response
      iSleep = SLEEP_MIN + rand(SLEEP_MAX - SLEEP_MIN)
      puts "Sleeping for #{iSleep} seconds"
      sleep(iSleep)
    }

    archivePurgeList()

  else
      puts "No #{PURGELIST_FILENAME} to purge"
  end

end

def archiveGoodList()
  strArchiveFile = "#{GOODLIST_FILENAME}" + Time.now.strftime("%Y%m%d_%H%M%S") + ".txt"
  puts "Moving #{GOODLIST_FILENAME} to #{strArchiveFile}"
  if (!File.directory?("./archives"))
    FileUtils.mkdir "./archives"
  end
  FileUtils.mv(GOODLIST_FILENAME, "./archives/" + strArchiveFile) 

end

def archiveFollowList()
  strArchiveFile = FOLLOWLIST_ARCHIVE_PREFIX + Time.now.strftime("%Y%m%d_%H%M%S") + FOLLOWLIST_ARCHIVE_SUFFIX 
  puts "Moving #{FOLLOWLIST_FILENAME} to #{strArchiveFile}"
  if (!File.directory?("./archives"))
    FileUtils.mkdir "./archives"
  end
  FileUtils.mv(FOLLOWLIST_FILENAME, strArchiveFile) 

end

def archivePurgeList()
  strArchiveFile = "purgelist" + Time.now.strftime("%Y%m%d_%H%M%S") + ".txt"
  puts "Moving #{PURGELIST_FILENAME} to #{strArchiveFile}"
  if (!File.directory?("./archives/purged"))
    FileUtils.mkdir "./archives/purged"
  end
  FileUtils.mv(PURGELIST_FILENAME, "./archives/purged/" + strArchiveFile) 

end

def makeGoodListCursor(username)
  cursor_id = makeGoodList(username, -1)
  sleep(REQUEST_SLEEP_INTERVAL)

  while(cursor_id != 0)
    puts "Making list for cursor page #{cursor_id}"
    cursor_id = makeGoodList(username, cursor_id)
    sleep(REQUEST_SLEEP_INTERVAL)
  
  end

end

def makeGoodList(username, cursorID)

  puts "Making #{GOODLIST_FILENAME} for #{username}"

  #read the checked.txt file into an array
  arrayChecked = Array.new
  if File.file?(CHECKED_FILENAME)
    File.open(CHECKED_FILENAME).each do |line|
    arrayChecked << line.chomp().to_i
    end
  end

  # use the access token as an agent to get the home timeline
  response = $access_token.request(:get, "https://api.twitter.com/1.1/followers/ids.json?cursor=#{cursorID}&screen_name=#{username}&count=#{USERS_PER_CURSOR_PAGE}")

  puts response
  #puts response["followers_count"]


#  puts "RESULT: " + JSON.parse(response.body)
  users = JSON.parse(response.body)
#  puts users["next_cursor"]
  puts users["ids"]
  users["ids"].each do |id|
    if (getGoodListCount() >= GOOD_LIST_MAX)
      puts "Reached Good List Max (#{GOOD_LIST_MAX})"
      exit
    end

    if (arrayChecked.include?(id))
      puts "Skipping #{id} - in checked.txt"
    else
      if (isGoodPerson(id))
        puts "ID: #{id}"
        f = File.open(GOODLIST_FILENAME, "a+")
        f.puts "#{id}"
        f.close
      else
        puts "Skipping #{id} - !isGoodPerson"
      end

#Not in the checked file, so add them
      fChecked = File.open(CHECKED_FILENAME, "a+")
      fChecked.puts "#{id}" 
      fChecked.close

      puts "Sleeping for #{$iSleepInterval}"
      sleep($iSleepInterval)

    end


  end


  puts "next_cursor: #{users["next_cursor"]}"
  return users["next_cursor"]

end

def makeFollowList()
  iFollowListCount = 0

  if (!File.file?(GOODLIST_FILENAME)) 
    puts "No #{GOODLIST_FILENAME}.  Create one using MAKEGOODLIST <user>"
  end

  while (File.file?(GOODLIST_FILENAME) && File.size?(GOODLIST_FILENAME) && iFollowListCount < MAX_PEOPLE_TO_FOLLOW)
    iToFollowCount = MAX_PEOPLE_TO_FOLLOW - iFollowListCount
    iFollowListCount += addToFollowList(iToFollowCount)

  end

end

def addToFollowList(iAddMax)
  iAdded = 0

  arrUsersList = Array.new 

  i = 0
  File.open(GOODLIST_FILENAME + ".tmp", "w") do |out_file|
    File.foreach(GOODLIST_FILENAME) do |line|
      if (i < USERS_PER_FRIEND_QUERY)
        arrUsersList << line.chomp()
      else
        out_file.puts line 
      end
      i += 1
    end
  end

  if (File.size(GOODLIST_FILENAME + ".tmp") > 0) 
    FileUtils.mv(GOODLIST_FILENAME + ".tmp", GOODLIST_FILENAME)
  else 
    FileUtils.rm(GOODLIST_FILENAME + ".tmp")
    FileUtils.rm(GOODLIST_FILENAME)
  end

  strUsersList = arrUsersList.map { |str| str }.join(",")
  puts "Checking: " + strUsersList



    response1 = $access_token.request(:get, "https://api.twitter.com/1.1/friendships/lookup.json?user_id=#{strUsersList}")
    connections = JSON.parse(response1.body)
    puts connections

    connections.each { |connection|
      if (iAdded < iAddMax) 

        doFollow = TRUE

        connection["connections"].each { |value|
          puts "Value: #{value}"
          if (value == "following" || value == "followed_by")
            doFollow = FALSE
          end
        }

        if (doFollow)
          f = File.open(FOLLOWLIST_FILENAME, "a+")
          f.puts connection["id"]
          f.close()
          iAdded += 1
        end

      else 
        puts "Putting #{connection["id"]} back in #{GOODLIST_FILENAME}" 
          f = File.open(GOODLIST_FILENAME, "a+")
          f.puts connection["id"]
          f.close()

      end
 
    }

    puts "Added #{iAdded} to #{FOLLOWLIST_FILENAME}"

    return iAdded

end

def displayUserID(username)
    response = $access_token.request(:get, "https://api.twitter.com/1.1/users/lookup.json?screen_name=#{username}")
    user = JSON.parse(response.body)
#    puts user
    uid = ""
    uid = user[0]["id"]

    user[0].map do |k, v|
      puts "Key: #{k} Value: #{v}"
    end
    puts "ID: #{uid}"

end

def displayUsername(user_id)
    response = $access_token.request(:get, "https://api.twitter.com/1.1/users/lookup.json?user_id=#{user_id}")
    user = JSON.parse(response.body)
    username = ""
    username = user[0]["screen_name"]

    user[0].map do |k, v|
      puts "Key: #{k} Value: #{v}"
    end

    puts "username: #{username}"

end

def isGoodPerson(user_id) 
  isGood = TRUE
  $iSleepInterval = 15 * 60 / 900

  response = $access_token.request(:get, "https://api.twitter.com/1.1/users/lookup.json?user_id=#{user_id}")
  user = JSON.parse(response.body)

  if (user.class == Hash && !user["errors"].nil?)
    puts "ERROR getting user #{user_id}"
    return false
  end

  u_screen_name = user[0]["screen_name"]
  puts "Handle: #{u_screen_name}"
  
  u_followers = user[0]["followers_count"]
  puts "Followers: #{u_followers}"
  if (u_followers < FOLLOWERS_LIMIT) 
    puts "Follower Count failed (#{u_followers} < #{FOLLOWERS_LIMIT})"
  end
  
  u_following = user[0]["friends_count"]
  puts "Following: #{u_following}"

  if (u_following > 0)
    u_following_ratio = (u_followers.to_f / u_following.to_f * 100.to_f).to_i
    puts "Follow ratio: #{u_following_ratio}"

    if (u_following_ratio > FOLLOW_RATIO_LIMIT)
      puts "Follower Ratio failed (#{u_following_ratio} > #{FOLLOW_RATIO_LIMIT})"
    end
  else
    u_following_ratio = INFINITY
  end


  if (!user[0]["status"].nil?)
    u_last_action = user[0]["status"]["created_at"]
    lastActionDate = DateTime.strptime(u_last_action, "%a %b %d %H:%M:%S %z %Y")  
    puts "Last action: #{u_last_action}"

    todayDate = DateTime.now
    puts lastActionDate
    puts todayDate 

    days_since_last_action = (todayDate - lastActionDate).to_i
    puts "Date: #{lastActionDate} Diff: #{days_since_last_action }"

    if (days_since_last_action > LAST_ACTION_LIMIT)
      puts "Last action failed (#{days_since_last_action} > #{LAST_ACTION_LIMIT})"
    end

  else
    days_since_last_action = 9999
  end

  if (u_followers > FOLLOWERS_LIMIT && u_following_ratio < FOLLOW_RATIO_LIMIT && days_since_last_action < LAST_ACTION_LIMIT)
    isGood = TRUE
  else
    isGood = FALSE
#    $iSleepInterval = REQUEST_SLEEP_INTERVAL 
  end 

  puts "*** #{u_screen_name} isGoodUser? #{isGood}" 
  
  return isGood 
end



def checkFollowerRatio(iToAdd) 
  checkPassed = true

  response = $access_token.request(:get, "https://api.twitter.com/1.1/account/verify_credentials.json")
  credentials = JSON.parse(response.body)

  puts "name: #{credentials['name']}"
  puts "id: #{credentials['id']}"
  id = credentials['id']
#  puts "UserID: #{id}" 

  response = $access_token.request(:get, "https://api.twitter.com/1.1/users/lookup.json?user_id=#{id}")
  user = JSON.parse(response.body)

  if (user.class == Hash && !user["errors"].nil?)
    puts "ERROR getting user #{user_id}"
    return false
  end

  u_screen_name = user[0]["screen_name"]
  puts "Handle: #{u_screen_name}"
  
  u_followers = user[0]["followers_count"]
  puts "Followers: #{u_followers}"
  if (u_followers < FOLLOWERS_LIMIT) 
    puts "Follower Count failed (#{u_followers} < #{FOLLOWERS_LIMIT})"
  end
  
  u_following = user[0]["friends_count"]
  puts "Following: #{u_following}"


  if (u_following + iToAdd > TWITTER_FOLLOW_LIMIT)
    puts "#{u_following + iToAdd} - Exceeded follow limit; Using ratio check method"

    puts "Checking: #{u_following} + #{iToAdd} / #{u_followers} >= #{TWITTER_RATIO_LIMIT}"
    iRatio = (u_following.to_f + iToAdd.to_f) / u_followers.to_f
    puts "#{iRatio}"
    if ((iRatio) >= TWITTER_RATIO_LIMIT)
      puts "Following too many people; Unfollow some people first"
      checkPassed = false
    else
      puts "Follow limit okay"
    end

  end


  return checkPassed
end



def isNotFollowing(user_list)
    response1 = $access_token.request(:get, "https://api.twitter.com/1.1/friendships/lookup.json?user_id=#{user_id}")
    connections = JSON.parse(response1.body)
    puts connections
    connections[0]["connections"].each { |value|
      puts "Value: #{value}"
      if (value == "following" || value == "followed_by")
        isGood = FALSE
        puts "Already following"
      end
    } 
      


end

def followGoodListByID()
  arrayGoodList = Array.new()
  File.open(GOODLIST_FILENAME).each do |line|
    arrayGoodList << line.chomp()
  end


  i = 1
  iCount = arrayGoodList.count
  arrayGoodList.each { |userid|

    puts "Following #{userid} #{i} of #{iCount}"

    response = $access_token.request(:post, "https://api.twitter.com/1.1/friendships/create.json?user_id=#{userid}&follow=true")
    puts response
    iSleep = SLEEP_MIN + rand(SLEEP_MAX - SLEEP_MIN)
    puts "Sleeping for #{iSleep} seconds"
    sleep(iSleep)
    i += 1
  }

   archiveGoodList()
end

def showRateLimit()
  # use the access token as an agent to get the home timeline
  response = $access_token.request(:get, "https://api.twitter.com/1.1/application/rate_limit_status.json?resources=help,users,search,statuses,friendships,application")

  puts response

  limits = JSON.parse(response.body)


#  if FALSE
  if TRUE
    limits["resources"].map do | limit_category |
      limit_category.map do |t|
       puts "t: #{t}"
       puts
      end
    end
  end

#  puts "Lookup - limit: #{limits["resources"]["users"]["/users/lookup"]["limit"]} remaining: #{limits["resources"]["users"]["/users/lookup"]["remaining"]}"


  h = limits["resources"]["users"]["/users/lookup"]
  puts "/users/lookup - limit: #{h["limit"]} remaining: #{h["remaining"]}"

  h = limits["resources"]["statuses"]["/statuses/home_timeline"]
  puts "/statuses/home_timeline - limit: #{h["limit"]} remaining: #{h["remaining"]}"

  h = limits["resources"]["statuses"]["/statuses/show/:id"]
  puts "/statuses/show:id - limit: #{h["limit"]} remaining: #{h["remaining"]}"
  
  h = limits["resources"]["friendships"]["/friendships/lookup"]
  puts "/friendships/lookup - limit: #{h["limit"]} remaining: #{h["remaining"]}"
  
  h = limits["resources"]["application"]["/application/rate_limit_status"]
  puts "/application/rate_limit_status - limit: #{h["limit"]} remaining: #{h["remaining"]}"
  

  
end

def getGoodListCount()
  iCount = -1

  if (File.exist?(GOODLIST_FILENAME))
    f = File.open(GOODLIST_FILENAME)
    iCount = f.count
    puts "Good list count: #{iCount}"
    f.close()
  end
  
  return iCount 

end


def makePurgeListDefault() 
  file_prefix = "followlist"
  strFileNames = Dir.entries("./archives")
  oldestFileName = nil
  oldestFileDate = nil

  doPurge = true

  strFileNames.each { | strFile |
    if (strFile.start_with?(file_prefix)) 
#      iStart = FOLLOWLIST_FILENAME.size
#Need to fix this to use FOLLOWLIST_ARCHIVE_PREFIX instead, but will have to rework how the Dir.entries are returned
      iStart = file_prefix.size
      iLength = "YYYYMMDD_hhmmss".size 
      dateFollow = DateTime.strptime(strFile[iStart, iLength], "%Y%m%d_%H%M%S") 
      puts "File: #{strFile} date: #{dateFollow}"

      if (oldestFileDate.nil? || dateFollow < oldestFileDate )
        oldestFileDate = dateFollow
        oldestFileName = strFile 
      end
    end
  }

  if (!oldestFileDate.nil?)
    todayDate = DateTime.now

    iDaysOld = (todayDate - oldestFileDate).to_i
    if (iDaysOld > 7)
      puts "Using: #{oldestFileName}"
      puts "iDaysOld: #{iDaysOld}"
      makePurgeList("./archives/" + oldestFileName)
    else
      doPurge = false
    end
  else
      doPurge = false

  end

  if (!doPurge)
      puts "No follow archive file to process"
  end

end


def makePurgeList(strFile) 

  if (File.exist?(strFile))

    contentsArray = Array.new()
    f = File.open(strFile)
    f.each_line {|line|
      contentsArray << line.chomp()
    }
    f.close()

    user_ids = ""
    puts "contentsArray: #{contentsArray.size()}"

    contentsArray.each_with_index do |line, index|
      puts "line: #{line}"
      $iSleepInterval = LOOKUP_SLEEP_INTERVAL 
      user_id = line.chomp()
      if (index % 100 > 0)
        user_ids += ","
      end
      user_ids += user_id

      if (index % 100 == 99 || index == contentsArray.size - 1)
        puts "checkPurgeList: #{user_ids}"
        puts "Count: #{user_ids.split(',').count}"
        checkPurgeList(user_ids)
#        iCount = 0
        user_ids = ""
        sleep(1)
        
      end
    
    end
  end

  
  if (!File.directory?("./archives/purged"))
    FileUtils.mkdir "./archives/purged"
  end
  strArchiveFile = "goodlistpurged" + Time.now.strftime("%Y%m%d_%H%M%S") + ".txt"
  FileUtils.mv(strFile, "./archives/purged/" + strArchiveFile) 

end

def checkPurgeList(user_ids) 
    whiteListArray = Array.new()
    f = File.open(WHITELIST_FILENAME)
    f.each_line {|line|
      whiteListArray << line.upcase().chomp()
    }
    f.close()

  
  response1 = $access_token.request(:get, "https://api.twitter.com/1.1/friendships/lookup.json?user_id=#{user_ids}")
  users = JSON.parse(response1.body)
  puts users 
  users.each { |connection|
    isFollowedBy = FALSE
    isFollowing = FALSE
    puts "screen_name: " + connection["screen_name"]
    
    if (!whiteListArray.include?(connection["screen_name"].upcase()))
      connection["connections"].each { |value|
        if (value == "followed_by")
          isFollowedBy = TRUE 
#          puts "IS followed_by"
        elsif (value == "following")
          isFollowing = TRUE 
#          puts "IS following"
        end
      }
      if (!isFollowedBy && isFollowing) 
        puts "PURGE"
        f = File.open(PURGELIST_FILENAME, "a+")
        f.puts connection["id"]
        f.close
      else
        puts "OK"
      end
    else
      puts "WHITELISTED"
    end
  } 
  
end


def checkPurge(user_id) 
  isFollowedBy = FALSE
  isFollowing = FALSE

  response = $access_token.request(:get, "https://api.twitter.com/1.1/users/lookup.json?user_id=#{user_id}")
  user = JSON.parse(response.body)

  if (user.class == Hash && !user["errors"].nil?)
    puts "ERROR getting user #{user_id}"
    return false
  end

  u_screen_name = user[0]["screen_name"]
  puts "Handle: #{u_screen_name}"
  
  response1 = $access_token.request(:get, "https://api.twitter.com/1.1/friendships/lookup.json?user_id=#{user_id}")
  connections = JSON.parse(response1.body)
  puts connections
  connections[0]["connections"].each { |value|
#    puts "Value: #{value}"
    if (value == "followed_by")
      isFollowedBy = TRUE 
      puts "IS followed_by"
    elsif (value == "following")
      isFollowing = TRUE 
      puts "IS following"
    end
  } 
  
  purgeUser = false
  if (!isFollowedBy && isFollowing) 
    purgeUser = true
  end
  return purgeUser
end



def displayUserURLByID(user_id)
    puts "https://twitter.com/intent/user?user_id=#{user_id}"

end



def getAllFollowers(username) 
  f = File.open(ALLFOLLOWERS_FILENAME, "w")

  iCursor = -1
  iNextCursor = -1
  keepLooping = true;

  while (keepLooping)

    #Check ratelimit
    response = $access_token.request(:get, "https://api.twitter.com/1.1/application/rate_limit_status.json?resources=followers")
    puts response
    limits = JSON.parse(response.body)
    puts "RATELIMIT"
    puts response.body
    iQueriesLeft = limits["resources"]["followers"]["/followers/list"]["remaining"]
    iQueryReset = limits["resources"]["followers"]["/followers/list"]["reset"]
    puts "iQueriesLeft: #{iQueriesLeft}, iQueryReset: #{iQueryReset} #{Time.at(iQueryReset)}"
    iSecondsUntilReset = Time.at(iQueryReset) - Time.new
    puts "Seconds until reset: #{iSecondsUntilReset}"

    if (iQueriesLeft > 0) 

      #Getting followers
      strRequest ="https://api.twitter.com/1.1/followers/list.json?screen_name=#{username}&count=#{FOLLOW_QUERY_COUNT}&cursor=#{iNextCursor}"

      puts "Request: #{strRequest}"

      response = $access_token.request(:get, strRequest) 
      puts response

      result = JSON.parse(response.body)

      if (result["users"].nil?) 
        puts "Something went wrong, response is nil"


        puts "#{response.body}"
        f.close

        return;
      end

#    puts response.body

      result["users"].each { | user |
        user_id = user["id"]
        user_screen_name = user["screen_name"]
        user_following = user["following"]
        strUser = "id: #{user_id}, screen_name: #{user_screen_name}, following: #{user_following}"
        puts strUser
        f.puts "#{strUser}"
      }

      iNextCursor = result["next_cursor"] 
      puts "Next Cursor: #{iNextCursor}"
      if (iNextCursor == 0) 
        keepLooping = false
      end
      sleep 10
    else
      iCushon = 10
      sleep iSecondsUntilReset + iCushon 

    end 
  end #while(keepLooping)

  f.close

end


def getAllFollowing(username) 
  f = File.open(ALLFOLLOWING_FILENAME, "w")

  iNextCursor = -1
  keepLooping = true;

  while (keepLooping)

    #Check ratelimit
    response = $access_token.request(:get, "https://api.twitter.com/1.1/application/rate_limit_status.json?resources=friends")
    puts response
    limits = JSON.parse(response.body)
    puts "RATELIMIT"
    puts response.body
    iQueriesLeft = limits["resources"]["friends"]["/friends/list"]["remaining"]
    iQueryReset = limits["resources"]["friends"]["/friends/list"]["reset"]
    puts "iQueriesLeft: #{iQueriesLeft}, iQueryReset: #{iQueryReset} #{Time.at(iQueryReset)}"
    iSecondsUntilReset = Time.at(iQueryReset) - Time.new
    puts "Seconds until reset: #{iSecondsUntilReset}"

    if (iQueriesLeft > 0) 

      #Getting friends (people followed, not necessarily follows back)
      strRequest ="https://api.twitter.com/1.1/friends/list.json?screen_name=#{username}&count=#{FOLLOW_QUERY_COUNT}&cursor=#{iNextCursor}"

      puts "Request: #{strRequest}"

      response = $access_token.request(:get, strRequest) 
      puts response

      result = JSON.parse(response.body)

      if (result["users"].nil?) 
        puts "Something went wrong, response is nil"


        puts "#{response.body}"
        f.close

        return;
      end

#    puts response.body

      result["users"].each { | user |
        user_id = user["id"]
        user_screen_name = user["screen_name"]
        user_following = user["following"] #this should always be true
        strUser = "id: #{user_id}, screen_name: #{user_screen_name}, following: #{user_following}"
        puts strUser
        strUser = "id: #{user_id}, screen_name: #{user_screen_name}"
        f.puts "#{strUser}"
      }

      iNextCursor = result["next_cursor"] 
      puts "Next Cursor: #{iNextCursor}"
      if (iNextCursor == 0) 
        keepLooping = false
      end
      sleep 10
    else
      iCushon = 10
      sleep iSecondsUntilReset + iCushon 

    end 
  end #while(keepLooping)

  f.close

end


def getAllFollowerIDs(username) 
  f = File.open(ALLFOLLOWERIDS_FILENAME, "w")

  iNextCursor = -1
  keepLooping = true;

  while (keepLooping)

    #Check ratelimit
    response = $access_token.request(:get, "https://api.twitter.com/1.1/application/rate_limit_status.json?resources=followers")
    puts response
    limits = JSON.parse(response.body)
    puts "RATELIMIT"
    puts response.body
    iQueriesLeft = limits["resources"]["followers"]["/followers/ids"]["remaining"]
    iQueryReset = limits["resources"]["followers"]["/followers/ids"]["reset"]
    puts "iQueriesLeft: #{iQueriesLeft}, iQueryReset: #{iQueryReset} #{Time.at(iQueryReset)}"
    iSecondsUntilReset = Time.at(iQueryReset) - Time.new
    puts "Seconds until reset: #{iSecondsUntilReset}"

    if (iQueriesLeft > 0) 

      #Getting followers
      strRequest ="https://api.twitter.com/1.1/followers/ids.json?screen_name=#{username}&cursor=#{iNextCursor}"

      puts "Request: #{strRequest}"

      response = $access_token.request(:get, strRequest) 
      puts response

      result = JSON.parse(response.body)

      if (result["ids"].nil?) 
        puts "Something went wrong, response is nil"


        puts "#{response.body}"
        f.close

        return;
      end

#    puts response.body

      result["ids"].each { | id |
        strID = "#{id}"
        puts strID
        f.puts "#{strID}"
      }

      iNextCursor = result["next_cursor"] 
      puts "Next Cursor: #{iNextCursor}"
      if (iNextCursor == 0) 
        keepLooping = false
      end
      sleep 10
    else
      iCushon = 10
      sleep iSecondsUntilReset + iCushon 

    end 
  end #while(keepLooping)

  f.close

end



def getAllFollowingIDs(username) 
  f = File.open(ALLFOLLOWINGIDS_FILENAME, "w")

  iNextCursor = -1
  keepLooping = true;

  while (keepLooping)

    #Check ratelimit
    response = $access_token.request(:get, "https://api.twitter.com/1.1/application/rate_limit_status.json?resources=friends")
    puts response
    limits = JSON.parse(response.body)
    puts "RATELIMIT"
    puts response.body
    iQueriesLeft = limits["resources"]["friends"]["/friends/ids"]["remaining"]
    iQueryReset = limits["resources"]["friends"]["/friends/ids"]["reset"]
    puts "iQueriesLeft: #{iQueriesLeft}, iQueryReset: #{iQueryReset} #{Time.at(iQueryReset)}"
    iSecondsUntilReset = Time.at(iQueryReset) - Time.new
    puts "Seconds until reset: #{iSecondsUntilReset}"

    if (iQueriesLeft > 0) 

      #Getting friends (people followed, not necessarily follows back)
      strRequest ="https://api.twitter.com/1.1/friends/ids.json?screen_name=#{username}&cursor=#{iNextCursor}"

      puts "Request: #{strRequest}"

      response = $access_token.request(:get, strRequest) 
      puts response

      result = JSON.parse(response.body)

      if (result["ids"].nil?) 
        puts "Something went wrong, response is nil"


        puts "#{response.body}"
        f.close

        return;
      end

#    puts response.body

      result["ids"].each { | id |
        strID = "#{id}"
        puts strID
        f.puts "#{strID}"
      }

      iNextCursor = result["next_cursor"] 
      puts "Next Cursor: #{iNextCursor}"
      if (iNextCursor == 0) 
        keepLooping = false
      end
      sleep 10
    else
      iCushon = 10
      sleep iSecondsUntilReset + iCushon 

    end 
  end #while(keepLooping)

  f.close

end



def getNotFollowBack()

  whiteListIDs = getWhiteListIDs()
#  puts "White LIst IDS"
#  puts whiteListIDs
#  puts "----------"

#  if (whiteListIDs.include?("35338217".to_i))
#    puts "found it"
#  end


  if (!File.exist?(ALLFOLLOWERIDS_FILENAME) || !File.exist?(ALLFOLLOWINGIDS_FILENAME))
    puts "Missing file.  Please run the following first"
    puts "  tweethelper.sh ALLFOLLOWERIDS <username>"
    puts "  tweethelper.sh ALLFOLLOWINGIDS <username>"
    reutrn
  end

#Read the two files into arrays
  allFollowingArray = Array.new()
  fAllFollowing = File.open(ALLFOLLOWINGIDS_FILENAME)
  fAllFollowing.each_line { |line|
    allFollowingArray << line.chomp()
  }
  fAllFollowing.close()

  allFollowerArray = Array.new()
  fAllFollowers = File.open(ALLFOLLOWERIDS_FILENAME)
  fAllFollowers.each_line {|line|
    allFollowerArray << line.chomp()
  }
  fAllFollowers.close()

#Loop through the following array, and find which ones aren't followers
  f = File.open(NOTFOLLOWBACKIDS_FILENAME, "w")

  allFollowingArray.each { | following_id |
    if (!allFollowerArray.include?(following_id) && !whiteListIDs.include?(following_id.to_i))
      strID = "#{following_id}"
      puts strID
      f.puts strID
    end
  }
  f.close

  makeNotFollowBackHTML()

end

def getWhiteListIDs()
  whiteListArray = Array.new()
  f = File.open(WHITELIST_FILENAME)
  f.each_line {|line|
    whiteListArray << line.upcase().chomp()
  }
  f.close()

#only works for up to 100
  puts whiteListArray.join(',')
  response = $access_token.request(:get, "https://api.twitter.com/1.1/users/lookup.json?screen_name=#{whiteListArray.join(',')}")

  whiteListIDs = Array.new()

  results = JSON.parse(response.body)

  results.each { | user |
      whiteListIDs << user["id"]
  }
  return whiteListIDs 


end


def makeNotFollowBackHTML() 
  fNotFollowBackIDs = File.open(NOTFOLLOWBACKIDS_FILENAME)

  usernameArray = Array.new

  i = 0
  strUserIDList = ""

  fNotFollowBackIDs.each_line { | line |
    strUserIDList += line.chomp 

    i += 1

    if (i >= 100) 
      puts strUserIDList
 
#      usernameArray << getUsernamesByID(strUserIDList)
      getUsernamesByID(strUserIDList).each { | user |
        usernameArray << user
      } 
      
      i = 0
      strUserIDList = ""
    else
  
      strUserIDList += ","
     end

  }

  if (strUserIDList != "") 
      getUsernamesByID(strUserIDList).each { | user |
        usernameArray << user
      } 
  end



  fNotFollowBackHTML = File.open(NOTFOLLOWBACKHTML_FILENAME, "w")

  fNotFollowBackHTML.puts "<html><head>"
  fNotFollowBackHTML.puts "<meta charset=\"utf-8\">"
  fNotFollowBackHTML.puts "</head><body>"

  usernameArray.each { | user |
    strLink = "<a href=\"https://twitter.com/#{user[0]}\">#{user[1]} (#{user[0]})</a><br>"
    puts strLink 
    fNotFollowBackHTML.puts strLink
  }


  fNotFollowBackHTML.puts "</body></html>"

  fNotFollowBackHTML.close
  fNotFollowBackIDs.close
end


def getUsernamesByID(user_ids)
      usernameArray = Array.new

      #Get usernames for everyone in user_ids comma separated list
      strRequest ="https://api.twitter.com/1.1/users/lookup.json?user_id=#{user_ids}"

      puts "Request: #{strRequest}"

      response = $access_token.request(:post, strRequest)
      puts response

      results = JSON.parse(response.body)
#      puts response.body
 
      results.each { | user |
        usernameArray << [user["screen_name"], user["name"]]
      }
      return usernameArray

end


def findNaughtyPeople(username) 
  badWordsArray = Array.new
  fBadWords = File.open(BADWORDS_FILENAME)
  fBadWords.each_line { | line |
    badWordsArray << line.chomp.upcase
  }
  fBadWords.close

  goodLanguageArray = Array.new
  fGoodLanguage = File.open(GOODLANGUAGE_FILENAME)
  fGoodLanguage.each_line { | line |
    goodLanguageArray << line.chomp.upcase
  }
  fGoodLanguage.close
  

  f = File.open(NAUGHTYPEOPLE_FILENAME, "w")

  iNextCursor = -1
  keepLooping = true;

  f.puts "<html><head>"
  f.puts "<meta charset=\"utf-8\">"
  f.puts "</head><body>"
  f.puts "<h1>Naughty People</h1>"

  while (keepLooping)

    #Check ratelimit
    response = $access_token.request(:get, "https://api.twitter.com/1.1/application/rate_limit_status.json?resources=friends")
    puts response
    limits = JSON.parse(response.body)
    puts "RATELIMIT"
    puts response.body
    iQueriesLeft = limits["resources"]["friends"]["/friends/list"]["remaining"]
    iQueryReset = limits["resources"]["friends"]["/friends/list"]["reset"]
    puts "iQueriesLeft: #{iQueriesLeft}, iQueryReset: #{iQueryReset} #{Time.at(iQueryReset)}"
    iSecondsUntilReset = Time.at(iQueryReset) - Time.new
    puts "Seconds until reset: #{iSecondsUntilReset}"

    if (iQueriesLeft > 0) 

      #Getting friends (people followed, not necessarily follows back)
      strRequest ="https://api.twitter.com/1.1/friends/list.json?screen_name=#{username}&count=#{FOLLOW_QUERY_COUNT}&cursor=#{iNextCursor}"

      puts "Request: #{strRequest}"

      response = $access_token.request(:get, strRequest) 
      puts response

      result = JSON.parse(response.body)

      if (result["users"].nil?) 
        puts "Something went wrong, response is nil"


        puts "#{response.body}"
        f.close

        return;
      end

#    puts response.body

      result["users"].each { | user |
        user_id = user["id"]
        user_name = user["name"]
        user_screen_name = user["screen_name"]
        user_bio = user["description"].upcase
        user_lang = user["lang"].upcase
    
        strLink = ""
        isNaughtyPerson = false
        badWordsArray.each { | strBadWord |
          if (user_bio.include?(strBadWord))
            isNaughtyPerson = true
            strLink += "<span style=\"color: red\">BAD WORD (#{strBadWord})</span>"
          end
        }

        if (!goodLanguageArray.include?(user_lang))
          isNaughtyPerson = true
          strLink += "<span style=\"color: blue\">LANGUAGE: #{user_lang}</span>"
        end

        if (isNaughtyPerson) 
          strUser = "id: #{user_id}, screen_name: #{user_screen_name}, bio: #{user_bio}, user_lang: #{user_lang}"
          puts strUser
          strLink = "<a href=\"https://twitter.com/#{user_screen_name}\">#{user_name} (#{user_screen_name})</a>" + strLink + "<br>"
          f.puts "#{strLink}"
        end
        
      }

      iNextCursor = result["next_cursor"] 
      puts "Next Cursor: #{iNextCursor}"
      if (iNextCursor == 0) 
        keepLooping = false
      end
      sleep 10
    else
      iCushon = 10
      sleep iSecondsUntilReset + iCushon 

    end 
  end #while(keepLooping)

  f.puts "</body></html>"

  f.close

  puts "Open #{Dir.pwd}/#{NAUGHTYPEOPLE_FILENAME} in a web browser"


end


def displayUsage() 
    puts "Usage: ruby twitter_oauth.rb <command> <options>"
    puts "Commands:" 
    puts "hometweets - list tweets in your timeline"
    puts "follow <username> - follows the specified user"
    puts "followgoodlist    - follows all IDs in #{GOODLIST_FILENAME} file"
    puts "followgoodlistusername  - follows all handles in #{GOODLIST_FILENAME} file"
    puts "makegoodlist <username>  - creates #{GOODLIST_FILENAME} file of IDs using followers of the specified user"
    puts "makefollowlist - creates #{FOLLOWLIST_FILENAME} from #{GOODLIST_FILENAME} based on follow status"

    puts "ratelimit - display rate limit information"
    puts "goodlistcount - how many people are in the good list"
    puts "getuserid <username> - return the ID for the specified handle"
    puts "getusername <user_id> - return the username for the specified ID"
    puts "isgoodperson <user_id> - returns if the specified user_id is a good person"
    puts "makepurgelist <filename>  - creates #{PURGELIST_FILENAME} file of IDs of users who do not follow back and not in #{WHITELIST_FILENAME}"
    puts "unfollowpurgelist - unfollows all IDs in #{PURGELIST_FILENAME} file"
    puts "purgeandunfollow - purges from the oldest archive file and unfollows them"
    puts "userurl <user_id> - displays the Twitter URL for the specified user_id"
    puts "allfollowerids <username> - generates file with ids of everyone following the specified user"
    puts "allfollowingids <username> - generates file with ids of everyone followed by the specified user"
    puts "notfollowbackcompareonly <username> - for everyone in the allfollowingids file, checks to see if there is a value in the allfollowerids file.  If not, user_id gets written to the notfollowback file.  HTML file is generated with links to all notfollowback users"
    puts "notfollowback <username> - generates the data files and returns the HTML file with people not following back "
    puts "naughtypeople - generates an HTML file with everyone who has #{BADWORDS_FILENAME} in their profile"


end


def main()
  readTokens()
 
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
    if (ARGV.count == 2)
      makeGoodListCursor(ARGV[1])
    else 
      displayUsage()
    end
  elsif (ARGV[0].upcase == "RATELIMIT") 
    showRateLimit() 
  elsif (ARGV[0].upcase == "GOODLISTCOUNT") 
    getGoodListCount() 
  elsif (ARGV[0].upcase == "GETUSERID") 
    if (ARGV.count == 2)
      displayUserID(ARGV[1]) 
    else 
      displayUsage()
    end
  elsif (ARGV[0].upcase == "GETUSERNAME") 
    if (ARGV.count == 2)
      displayUsername(ARGV[1]) 
    else 
      displayUsage()
    end
  elsif (ARGV[0].upcase == "ISGOODPERSON") 
    if (ARGV.count == 2)
      puts isGoodPerson(ARGV[1]) 
    else 
      displayUsage()
    end
  elsif (ARGV[0].upcase == "PURGEANDUNFOLLOW") 
      makePurgeListDefault() 
      unfollowPurgeList()

  elsif (ARGV[0].upcase == "MAKEPURGELIST") 
    if (ARGV.count == 2)
      puts makePurgeList(ARGV[1]) 
    elsif (ARGV.count == 1)
      makePurgeListDefault() 
    end
  elsif (ARGV[0].upcase == "UNFOLLOWPURGELIST") 
      unfollowPurgeList()
  elsif (ARGV[0].upcase == "MAKEFOLLOWLIST") 
      makeFollowList()
  elsif (ARGV[0].upcase == "FOLLOWFOLLOWLIST") 
      followFollowList()
  elsif (ARGV[0].upcase == "USERURL") 
    if (ARGV.count == 2)
      puts displayUserURLByID(ARGV[1]) 
    else 
      displayUsage()
    end
  elsif (ARGV[0].upcase == "DELETEDMS") 
      deleteDirectMessages()
  elsif (ARGV[0].upcase == "CHECKFOLLOWERRATIO") 
    if (ARGV.count == 2)
      checkFollowerRatio(ARGV[1].to_i)
    else 
      checkFollowerRatio(0) 
    end
  elsif (ARGV[0].upcase == "ALLFOLLOWERS") 
    if (ARGV.count == 2)
      getAllFollowers(ARGV[1])
    else
      puts "Usage: ALLFOLLOWERS <username>"
    end
  elsif (ARGV[0].upcase == "ALLFOLLOWING") 
    if (ARGV.count == 2)
      getAllFollowing(ARGV[1])
    else
      puts "Usage: ALLFOLLOWING <username>"
    end
  elsif (ARGV[0].upcase == "ALLFOLLOWERIDS") 
    if (ARGV.count == 2)
      getAllFollowerIDs(ARGV[1])
    else
      puts "Usage: ALLFOLLOWERIDS <username>"
    end
  elsif (ARGV[0].upcase == "ALLFOLLOWINGIDS") 
    if (ARGV.count == 2)
      getAllFollowingIDs(ARGV[1])
    else
      puts "Usage: ALLFOLLOWINGIDS <username>"
    end
  elsif (ARGV[0].upcase == "NOTFOLLOWBACKCOMPAREONLY") 
      getNotFollowBack()
  elsif (ARGV[0].upcase == "NOTFOLLOWBACK") 
    if (ARGV.count == 2)
      getAllFollowerIDs(ARGV[1])
      getAllFollowingIDs(ARGV[1])
      getNotFollowBack()
      puts "Open #{Dir.pwd}/#{NOTFOLLOWBACKHTML_FILENAME} in a web browser"
    else 
      puts "Usage: NOTFOLLOWBACK <username>"

    end
      
  elsif (ARGV[0].upcase == "NAUGHTYPEOPLE") 
    if (ARGV.count == 2)
      findNaughtyPeople(ARGV[1]);
    else
      puts "Usage: NAUGHTYPEOPLE <username>"
    end
  elsif (ARGV[0].upcase == "ARCHIVEFOLLOWLIST") 
    archiveFollowList()
  else 
    puts "Invalid option"
    displayUsage()
  end



end

main()

