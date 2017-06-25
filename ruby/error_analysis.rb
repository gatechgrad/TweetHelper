f = File.new("followerrors.txt", "r")

while (strLine = f.gets())
  tokens = strLine.split(' ')
  if (tokens[0] == "Following" && tokens.size > 1)
#    puts "line: #{strLine}"
    puts tokens[1]
  end
end

f.close()
