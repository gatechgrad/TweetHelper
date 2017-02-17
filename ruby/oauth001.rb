require 'oauth'
require 'json'


# Exchange your oauth_token and oauth_token_secret for an AccessToken instance.
def prepare_access_token(oauth_token, oauth_token_secret)
#    consumer = OAuth::Consumer.new("APIKey", "APISecret", { :site => "https://api.twitter.com", :scheme => :header })
    consumer = OAuth::Consumer.new("1hD2hQz32RFpuF8OkA1FNngzs", "0BLeOgnZHsaQEbmSy1Kkq4TrCOGio4UBkRsrIe13EWp2rM4dVh", { :site => "https://api.twitter.com", :scheme => :header })
     
    # now create the access token object from passed values
    token_hash = { :oauth_token => oauth_token, :oauth_token_secret => oauth_token_secret }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
 
    return access_token
end
 
# Exchange our oauth_token and oauth_token secret for the AccessToken instance.
access_token = prepare_access_token("21630362-EkPAfZkWKAlAcWDL7I0dFYGRNuYatWIwXJxdI9IdI", "m21nyS2Ag4W5Pf8XZux2OjQvrbnWdSJBhFCIzBh5b1Ztx")
 
# use the access token as an agent to get the home timeline
response = access_token.request(:get, "https://api.twitter.com/1.1/statuses/home_timeline.json")

puts response
#puts response["followers_count"]


i = 0
tweets = JSON.parse(response.body)
tweets.map do | tweet |
  if (i < 10) 
    puts i.to_s + ": User: " + tweet["user"]["name"] + " " +
    "Tweet: " + tweet["text"]
  end
  i += 1
end

