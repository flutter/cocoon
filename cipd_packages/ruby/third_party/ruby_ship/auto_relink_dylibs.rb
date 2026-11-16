require "fileutils"
require "shellwords"



@current_dir = File.expand_path(File.dirname(__FILE__))
@new_dylib_path = File.join(@current_dir, "..", "bin", "darwin_ruby", "dylibs")

FileUtils.mkdir_p(@new_dylib_path)

# Extracts the LC_RPATH entries from `otool -l` output.
def parse_rpaths(otool_l_output)
	otool_l_output.scan(/cmd\s+LC_RPATH\s+cmdsize\s+\d+\s+path\s+(.+?)\s+\(offset\s+\d+\)/).flatten
end

# Returns the LC_RPATH entries of a Mach-O file.
def rpaths_for_file(file)
	parse_rpaths(`otool -l #{Shellwords.escape(file)} 2> /dev/null`)
end

# Resolves a dependency reported by `otool -L` to a real file on disk.
#
# Absolute paths are returned unchanged. Homebrew bottles (e.g. brotli 1.2.0)
# now reference sibling libraries as `@rpath/libfoo.dylib` (or `@loader_path/`,
# `@executable_path/`), which is not a filesystem path and cannot be copied
# directly. For those, look for the library next to the referencing library's
# original location (source_dir), then in each of its LC_RPATH entries, then
# among the dylibs that were already copied. Returns nil if nothing matches.
#
# `@loader_path` is expanded relative to source_dir. `@executable_path` depends
# on whichever executable ends up loading the library, which is not known at
# packaging time, so those references are only matched by basename.
#
# See https://github.com/flutter/flutter/issues/164665 and
# https://ci.chromium.org/b/8669644619614462833.
def resolve_dylib_path(libfile, source_dir, rpaths)
	return libfile unless libfile.start_with?("@")

	basename = File.basename(libfile)
	candidates = []
	if libfile.start_with?("@loader_path/")
		candidates << File.expand_path(libfile.sub(/\A@loader_path/, source_dir))
	end
	candidates << File.join(source_dir, basename)
	rpaths.each do |rpath|
		next if rpath.start_with?("@executable_path")
		rpath = File.expand_path(rpath.sub(/\A@loader_path/, source_dir))
		candidates << File.join(rpath, basename)
	end
	candidates << File.join(@new_dylib_path, basename)

	candidates.find { |candidate| File.file?(candidate) }
end

# `source_dir` is the directory the file was originally copied from. It is used
# to resolve `@rpath`-style dependencies, since a copied dylib no longer sits
# next to its siblings.
def fix_dylib_for_file(file, source_dir = File.dirname(File.expand_path(file)))
	results = `otool -L "#{file}"` #Will get information about which dylibs to link

	if results.is_a?(String) && results != "" && !results.include?("is not an object file")  && !results.include?("Assertion failed:")
		# puts "---------------------------------"
		puts "--RELINKING--: #{file}"
		# puts "---------------------------------"
		expanded = File.expand_path(file)

		#Setting new ID for this if needed
                id_path = File.join("darwin_ruby", "dylibs", File.split(expanded)[-1])
		id_reset_results = `install_name_tool -id #{id_path} #{file} 2> /dev/null` #Will link the current file to itself

		lines = results.split("\n")
		lines = [] unless lines
		itterate = lines[1..-1]
		itterate = [] unless itterate

		rpaths = nil

		itterate.each do |libfile_line|
			libfile = libfile_line.split(" (compatibility version")[0].strip
			libfile = libfile.split("(")[0]

			next if libfile.include?(@new_dylib_path) # We have already fixed this one
			next if libfile.include?("/usr/lib/") # These are global and assumed to be present on all versions of osx
			next if libfile.include?("/System/Library/") # Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation

			rpaths ||= rpaths_for_file(file) if libfile.start_with?("@")
			source_libfile = resolve_dylib_path(libfile, source_dir, rpaths || [])
			if source_libfile.nil?
				puts "ERROR: could not resolve #{libfile} referenced by #{file} (source dir: #{source_dir}, rpaths: #{rpaths.inspect})"
				exit 1
			end

                        new_libfile = File.join(@new_dylib_path, File.split(source_libfile)[-1])

			unless File.file?(new_libfile)
				FileUtils.copy(source_libfile, new_libfile)
				puts "--COPIED-- #{new_libfile}"
				fix_dylib_for_file(new_libfile, File.dirname(source_libfile))
			end

			# `libfile` must be the exact string from the load command (e.g. `@rpath/libfoo.dylib`).
			relink_command_results = `install_name_tool -change #{libfile} #{new_libfile} #{file} 2> /dev/null` # Will relink external library
			puts "Linked: #{new_libfile} to #{file}"

			if relink_command_results != "" && !relink_command_results.include?("error:")
				puts "relinked in #{file} link: #{libfile} to #{new_libfile}"
			end
		end
	end
end

puts "Relinking files from: #{File.dirname(File.expand_path($0))}"

folders = [File.expand_path(File.join(File.dirname(File.expand_path($0)), "..", "bin", "darwin_ruby"))]

full = folders.map{|f| Dir[File.join(f, '**', '*')]}
actual_files = full.flatten(1).uniq.select{|e| File.file? e}


actual_files.each do |file|
	fix_dylib_for_file(file)
end

puts "Relinking of dylib done"
