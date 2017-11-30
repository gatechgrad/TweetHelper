2017 Levi D. Smith

WARNING:  Mass following Twitter accounts can supposedly get your Twitter account banned.  Use with caution and only if you know what you're doing!

Create text file in the conf directory called tokens.txt and put in the following values on separate lines:

consumer_key
consumer_secret
oauth_token
oauth_token_secret

I did this to keep me from checking in source code with these keys.  Put ruby/conf/tokens.txt in the .gitignore file.

If you see something like below followed by a stack trace, the Consumer Key or Consumer Secret values are wrong.  You get these from https://dev.twitter.com > My apps > select app > Keys and Access Tokens tab.
Now at https://apps.twitter.com
#<Net::HTTPUnauthorized:0x007fa6078811c0>
twitter_oauth.rb:50:in `[]': no implicit conversion of String into Integer (TypeError)

250 follows or unfollows a day.  Users can't be unfollowed for 5 days.  Those are probably good rules to follow to prevent from being suspended.

Typical usage:
#Follow everyone who is following @GeorgiaTech
ruby twitter_oauth.rb makegoodlist GeorgiaTech
ruby twitter_oauth.rb makefollowlist 
ruby twitter_oauth.rb followfollowlist

#Five days later, remove everyone who didn't follow back (replace DATE with the date of the archived file)
ruby twitter_oauth.rb makepurgelist archives/followlist<DATE>.txt
ruby twitter_oauth.rb unfollowpurgelist

Who isn't following back usage:
ruby twitter_oauth.rb allfollowerids <username>
ruby twitter_oauth.rb allfollowingids <username>
ruby twitter_oauth.rb notfollowback 
Then open ruby/data/notfollowback.html in a web browser
