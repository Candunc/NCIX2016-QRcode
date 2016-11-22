lfs = require("lfs")
json = require("json")

function exec(input)
	local handle = io.popen(input.." 2>&1")
	local data = handle:read("*a")
	handle:close()

	return data
end

function hash(input)
	return string.sub(exec("sha256sum "..input),1,64)
end

function barcode(input)
	local data = exec("zbarimg output/"..input)
	return string.sub(data,1,(string.find(data,"\n"))-1)
end

function video(input)
	if input == nil then
		return json.decode(exec("youtube-dl -j --playlist-items 1 https://www.youtube.com/user/NCIXcom/videos"))
	else
		return json.decode(exec("youtube-dl -j \""..input.."\""))
	end
end


function quit()
	local file = io.open("database.json","w")
	file:write(json.encode(db))
	file:close()

	os.execute("rm output/*")

	os.exit()
end

file = io.open("database.json","r")
if file == nil then
	db = {}
else
	db = json.decode(file:read("*a"))
	file:close()
end

input = video(arg[1]) --Doesn't matter if arg[1] is nil, we catch that.

if db[input["id"]] ~= nil then
	print("Video already processed.")
	os.exit()
end

db[input["id"]] = true
os.execute("youtube-dl -f best -o temp.mp4 "..input["webpage_url"]) --Best is 720p, probably overkill for QR code scraping but oh well.

os.execute("rm -r output; mkdir output")
os.execute("ffmpeg -i temp.mp4 -vf fps=1 output/img%03d.png")
os.execute("rm temp.mp4")

for file in lfs.dir("output") do
	if file ~= "." and file ~= ".." then
		a = barcode(file)
		if string.sub(a,1,8) == "QR-Code:" then
			print("Found barcode in file "..file)
			os.execute("mv output/"..file.." ./"..input["id"]..".png")
			quit()
		end
	end
end

print("No QR Codes found.")
quit()
