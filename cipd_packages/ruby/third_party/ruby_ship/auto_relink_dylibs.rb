require "fileutils"

@new_dylib_path = File.join("bin", "shipyard", "darwin_ruby", "dylibs")

@current_dir = FileUtils.pwd

FileUtils.mkdir_p(@new_dylib_path)

def fix_dylib_for_file(file)
	results = `otool -L #{file}` #Will get information about which dylibs to link
	
	if results.is_a?(String) && results != "" && !results.include?("is not an object file")  && !results.include?("Assertion failed:")
		# puts "---------------------------------"
		puts "--RELINKING--: #{file}"
		# puts "---------------------------------"
		expanded = File.expand_path(file)
		
		#Setting new ID for this if needed
		id_path = File.join("bin", "shipyard", "darwin_ruby", expanded.split(File.join(@current_dir, "bin", "shipyard","darwin_ruby"))[-1])
		id_reset_results = `sudo install_name_tool -id #{id_path} #{file} 2> /dev/null` #Will link the current file to itself

		lines = results.split("\n")
		lines = [] unless lines
		itterate = lines[1..-1]
		itterate = [] unless itterate


		itterate.each do |libfile_line|
			libfile = libfile_line.split(" (compatibility version")[0].strip
			libfile = libfile.split("(")[0]

			next if libfile.include?(@new_dylib_path) #We have already fixed this one
			next if libfile.include?("/usr/lib/") #These are global and assumed to be present on all versions of osx
			next if libfile.include?("/System/Library/")#Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation
			
			new_libfile = File.join(@new_dylib_path, libfile.split(File.join("",""))[-1])

			unless File.file?(new_libfile)
				FileUtils.copy(libfile, new_libfile)
				puts "--COPIED-- #{new_libfile}"
				fix_dylib_for_file(new_libfile)
			end
			
			relink_command_results = `sudo install_name_tool -change #{libfile} #{new_libfile} #{file} 2> /dev/null` #Will relink external library
			puts "Linked: #{new_libfile} to #{file}"

			if relink_command_results != "" && !relink_command_results.include?("error:")
				puts "relinked in #{file} link: #{libfile} to #{new_libfile}"
			end
		end
	end
end

puts File.dirname(File.expand_path($0))

folders = [File.expand_path(File.join(File.dirname(File.expand_path($0)), "..", "bin", "shipyard", "darwin_ruby"))]

full = folders.map{|f| Dir[File.join(f, '**', '*')]}
actual_files = full.flatten(1).uniq.select{|e| File.file? e}


actual_files.each do |file|
	fix_dylib_for_file(file)
end

puts "Relinking of dylib done"
