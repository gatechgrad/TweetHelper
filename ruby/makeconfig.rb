#2020 Levi D. Smith - levidsmith.com
require 'fileutils'

class MakeConfig

	def initialize()
		puts 'MakeConfig for TweetHelper'
		puts '2020 Levi D. Smith - levidsmith.com'
		puts '-----------------------------------'

		makeConfigDir()
		menu()
	end
	
	def menu()
		keepLooping = true
		
		while(keepLooping)
			puts '1) make token file'
			puts '2) make white list'
			puts '3) make badwords file'
#			puts '4) make good languages file'
			puts 'Q) quit'
			
			strInput = gets().strip.upcase
			
			if (strInput[0] == 'Q')
				keepLooping = false
			elsif (strInput[0] == '1')
				makeTokenFile()
			elsif (strInput[0] == '2')
				makeWhiteList()
			elsif (strInput[0] == '3')
				makeBadWords()
#			elsif (strInput[0] == '4')
#				makeGoodLanguage()
			end
		
		end

	end
	
	def makeConfigDir()
		if (!Dir.exist?('./conf'))
			puts 'conf directory not found, creating it'
			FileUtils.mkdir('conf')
		end
	
	end
	
	
	
	def makeTokenFile()
		
		puts 'See https://developer.twitter.com/en/apps for information on'
		puts 'creating token keys'
		puts '-----------------------------------'
		
		puts "Enter Consumer Key"
		strConsumerKey = gets().strip
		
		puts "Enter Consumer Secret"
		strConsumerSecret = gets().strip
		
		puts "Enter OAuth Token"
		strOAuthToken = gets().strip
		
		puts "Enter OAuth Token Secret"
		strOAuthTokenSecret = gets().strip
		
		f = File.open('./conf/tokens.txt', "w")
		f.puts(strConsumerKey)
		f.puts(strConsumerSecret)
		f.puts(strOAuthToken)
		f.puts(strOAuthTokenSecret)
		
		f.close()
		
		
		
	end
	
	def makeWhiteList()
	
		puts 'Making conf/whitelist.txt file'
		keepLooping = true
		strNames = Array.new
		while (keepLooping)
			puts "Enter handle (leave blank to quit)"
			strInput = gets().strip
			
			if (strInput == "")
				keepLooping = false
			else
				strNames.push(strInput)
			end
		end
		
		
		f = File.open('./conf/whitelist.txt', 'a')
		strNames.each { |strName|
			puts "name: #{strName}"
			f.puts(strName)
		}
		f.close
	
	
	end


	def makeBadWords()
	
		puts 'Making conf/badwords.txt file'
		keepLooping = true
		strNames = Array.new
		while (keepLooping)
			puts "Enter bad word (leave blank to quit)"
			strInput = gets().strip
			
			if (strInput == "")
				keepLooping = false
			else
				strNames.push(strInput)
			end
		end
		
		
		f = File.open('./conf/badwords.txt', 'a')
		strNames.each { |strName|
			puts "name: #{strName}"
			f.puts(strName)
		}
		f.close
	
	
	end

	def makeGoodLanguage()
	
		puts 'Making conf/goodlanguage.txt file'
		keepLooping = true
		strNames = Array.new
		while (keepLooping)
			puts "Enter good language (leave blank to quit)"
			strInput = gets().strip
			
			if (strInput == "")
				keepLooping = false
			else
				strNames.push(strInput)
			end
		end
		
		
		f = File.open('./conf/goodlanguage.txt', 'a')
		strNames.each { |strName|
			puts "name: #{strName}"
			f.puts(strName)
		}
		f.close
	
	
	end

	
	
end

makeconfig = MakeConfig.new

