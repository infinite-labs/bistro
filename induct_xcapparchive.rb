require 'ilabs/bistro'
require 'ilabs/bistro/induct'
require 'ilabs/apple_ios/mobile_provision'

require 'osx/cocoa'
include OSX

def main
	ILabs::Bistro.induct(XCAppArchiveInductor)
end

class XCAppArchiveInductor < ILabs::Bistro::Inductor
	def add_option_parser_flags(opts)
		@provision = true
		
		opts.on('-p', '--[no-]provisioning', 'Induct (or prevent inducting) the provisioning profile for the app archive into the vault, if not already present. The default is to induct.') do |provision|
			@provision = provision
		end
	end
	
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
	
	def induct(v)
		super(v)
		
		profile_uuid = app_archive_info['XCProfileUUID']
		if profile_uuid and @provision
			profile_vault_id = [platform, 'ProvisioningProfiles', profile_uuid].join '/'
			a = ILabs::Bistro::Artifact.at(v.path.subpath(profile_vault_id))
			if not a
				m = ILabs::Apple_iOS::MobileProvision.select { |m| m.uuid == profile_uuid }
				a = v.induct_into(profile_vault_id, [m.path])
				a.save
			end
		end
	end
end

main
