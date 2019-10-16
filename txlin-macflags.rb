#!/usr/bin/env ruby
path = "/Library/Developer/TXLin"

out = ''
ARGV.each do |arg|
	if arg == '--cflags' then
		out += ' -I' + path + '/include -I' + path + '/include/SDL2 ' + `"#{path}//bin/sdl2-config" --cflags`
	elsif arg == '--libs' then
		out += ' -pthread ' + `"#{path}//bin/sdl2-config" --libs` + ' -L' + path + '/lib -lSDL2_ttf -lfreetype'
		if `uname`.include? 'Linux' then
			out += ' -dl'
		end
	else
		out = 'Usage: ruby "' + File.absolute_path(__FILE__) + '" [--cflags/--libs]' 
	end
end

puts out
exit 0
