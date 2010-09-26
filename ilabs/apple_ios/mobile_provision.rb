require 'osx/cocoa'

module ILabs; end
module ILabs::Apple_iOS; end

class ILabs::Apple_iOS::MobileProvision
	def initialize(path)
		content = nil
		File.open(path, "r") do |file|
			content = file.read
		end
		
		start_index = content.index('<?xml')
		raise "Can't find the XML property list segment in mobileprovision file #{path}" unless start_index
		
		end_index = content.index('</plist>', start_index)
		raise "Can't find the XML property list segment ending in mobileprovision file #{path}" unless end_index
		
		dict = OSX.load_plist(content[start_index, end_index - start_index + '</plist>'.length])
		@profile_info = dict
		@path = path
	end
	
	attr_reader :profile_info, :path
	
	def self.all(profiles_path = nil)
		profiles = []
		profiles_path ||= File.join(ENV['HOME'], 'Library', 'MobileDevice', 'Provisioning Profiles')
		
		raise "Not an (existing?) directory: #{profiles_path}" unless File.directory? profiles_path
		
		Dir.glob(File.join profiles_path, '*.mobileprovision') do |file|
			profiles << self.new(file)
		end
		
		return profiles
	end
	
	def inspect
		"#<MobileProvision Name=#{@profile_info['Name']}, UUID=#{@profile_info['UUID']}>"
	end
	
	def self.select
		w = self.all.select { |x| yield(x) }
		w[0]
	end
	
	def [](x)
		@profile_info[x]
	end
	
	def uuid
		@profile_info['UUID']
	end
	
	def name
		@profile_info['Name']
	end
	
	def provisioned_devices
		@profile_info['ProvisionedDevices']
	end
end
