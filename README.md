```
2017 Levi D. Smith

WARNING:  Mass following and unfollowingTwitter accounts can get your Twitter app and Twitter account suspended or banned.  Use with caution and only if you know what you're doing!

Create text file in the conf directory called tokens.txt and put in the following values on separate lines:

consumer_key
consumer_secret
oauth_token
oauth_token_secret

I did this to keep me from checking in source code with these keys.  Put ruby/conf/tokens.txt in the .gitignore file.

YOU MUST CREATE YOUR OWN TWITTER APP ON THE TWITTER DEVELOPER SITE!  There is plenty of documentation available on how to setup a Twitter app.
https://developer.twitter.com/en/apps


If you see something like below followed by a stack trace, the Consumer Key or Consumer Secret values are wrong.  You get these from https://dev.twitter.com > My apps > select app > Keys and Access Tokens tab.

Now at https://apps.twitter.com

#<Net::HTTPUnauthorized:0x007fa6078811c0>

twitter_oauth.rb:50:in `[]': no implicit conversion of String into Integer (TypeError)

===========================

Ruby oauth gem must be installed!
$ sudo gem install oauth
Fetching: oauth-0.5.4.gem (100%)
Successfully installed oauth-0.5.4
Parsing documentation for oauth-0.5.4
Installing ri documentation for oauth-0.5.4
Done installing documentation for oauth after 1 seconds
1 gem installed

===========================


Suggested guidelines: No more than 250 follows or unfollows a day.  Users can't be unfollowed for 5 days.  Those are probably good rules to follow to prevent from being suspended.

===========================

Typical usage (all of the commands assume that you are in the ruby directory):

#Follow everyone who is following @GeorgiaTech
ruby twitter_oauth.rb makegoodlist GeorgiaTech

#The following two lines can be run multiple times until the goodlist is empty
ruby twitter_oauth.rb makefollowlist 
ruby twitter_oauth.rb followfollowlist

===========================

#Days later, remove everyone who didn't follow back
#Update - recommend using the notfollowback option instead
ruby twitter_oauth.rb makepurgelist #now detects the oldest purgelist file
ruby twitter_oauth.rb unfollowpurgelist

===========================

Who isn't following back usage:

ruby twitter_oauth.rb allfollowerids <username>
ruby twitter_oauth.rb allfollowingids <username>

#Update - notfollowback now automatically runs the allfollowerids and allfollowingids commands,
#so those no longer need to be entered
ruby twitter_oauth.rb notfollowback 

Then open data/notfollowback.html in a web browser

===========================

Naughty People usage

Put naughty words on separate lines in conf/badwords.txt

Put language codes in conf/goodlanguage.txt

ruby twitter_oauth.rb naughtypeople <username>

Then open data/naughtypeople.html in a web browser
```
