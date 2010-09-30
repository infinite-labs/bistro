require 'ilabs/bistro'
require 'ilabs/bistro/induct'

require 'osx/cocoa'
include OSX

def main
	ILabs::Bistro.induct(XCAppArchiveInductor)
end

class XCAppArchiveInductor < ILabs::Bistro::Inductor
	def options= o
		@options = o
		@app_archive_info = nil
	end
	
	def app_archive_info
		unless @app_archive_info
			archive_plist = source_path.subpath "ArchiveInfo.plist"
			raise "File does not exist: #{archive_plist}" unless archive_plist.exist?
		
			@app_archive_info = NSDictionary.dictionaryWithContentsOfFile archive_plist.to_s
			raise "Could not read property list from #{archive_plist}" unless @app_archive_info
		end
		
		@app_archive_info
	end
	
	def platform
		"com.apple.ios"
	end
	
	def identifier
		options[:identifier] || app_archive_info['CFBundleIdentifier']
	end
	
	def files_to_copy
		[source_path.subpath('ArchiveInfo.plist'), source_path.subpath( app_archive_info['XCApplicationFilename']), source_path.subpath(app_archive_info['XCApplicationFilename'] + '.dSYM')]
	end	
end

main
