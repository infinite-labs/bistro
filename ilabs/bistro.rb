
require 'json'
load File.join(File.dirname(__FILE__), 'uuid.rb')
require 'optparse'

module ILabs; end
module ILabs::Bistro

	class Artifact
		def initialize(p)
			raise "#{path} not a(n existing?) directory." unless File.directory? p
			@path = Path.new p
			
			@meta = {}
			meta_file = @path.join 'ArtifactInfo.json'
			if File.exist? meta_file
				File.open(meta_file, 'r') do |file|
					@meta = JSON.load(file)
					raise "ArtifactInfo.json does not contain a JSON object (Hash)." unless @meta.kind_of? Hash
				end
			end
		end
		
		attr_reader :path, :meta
		
		def update
			meta['State'] = UUID.create_random.to_s
		end
		
		def save(options = {})
			options[:update] = true if options[:update].nil?
			update unless not options[:update]
			
			meta_file = path.join 'ArtifactInfo.json'
			File.open(meta_file, 'w') do |file|
				JSON.dump(meta, file)
			end
		end
		
		def updated_since_state? s
			@meta['State'] != s
		end
	end
	
	class Path
		def initialize(path, relative_to='.')
			@path_components = File.expand_path(path, relative_to).split '/'
		end
		
		attr_reader :path_components
		
		def to_s
			path_components.join '/'
		end
		
		def ==(x)
			path_components == x.path_components
		end
		
		def eql?(x)
			x.kind_of? Path and self == x
		end
		
		def inspect
			"#<Path '#{to_s}'>"
		end
		
		def parent_of? x
			x.path_components.length > path_components.length and x.path_components[0, path_components.length] == path_components
		end
		
		def join(*args)
			File.join(path_components.join('/'), *args)
		end
		
		def subpath(*args)
			self.class.new join(*args)
		end
	end
	
	class Vault
		def initialize(p)
			raise "#{path} not a(n existing?) directory." unless File.directory? p
			@path = Path.new p
			
			@meta = {}
			meta_file = path.join 'VaultInfo.json'
			if File.exist? meta_file
				File.open(meta_file, 'r') do |file|
					@meta = JSON.load(file)
					raise "VaultInfo.json does not contain a JSON object (Hash)." unless @meta.kind_of? Hash
				end
			end
			
			@meta['Artifacts'] ||= []
			raise "Artifacts in VaultInfo.json does not contain a JSON array." unless @meta['Artifacts'].kind_of? Array
		end
		attr_reader :path, :artifacts
		
		def add_artifact(a)
			raise "This artifact is not in the Vault!" unless path.parent_of? a.path
			unless @meta['Artifacts'].include? a.path.to_s
				@meta['Artifacts'] << a.path.to_s
				save
			end
		end
		
		def delete_artifact(a)
			if @meta['Artifacts'].include? a.path.to_s
				@meta['Artifacts'].delete a.path.to_s
				save
			end
		end
		
		def save
			meta_file = path.join 'VaultInfo.json'
			File.open(meta_file, 'w') do |file|
				JSON.dump(@meta, file)
			end
		end
	end
	
	def self.induct(inductor, args = nil)
		args ||= ARGV.dup
		
		OptionParser.new do |opt|
			# Default opts go here
			inductor.add_options(opt) if inductor.responds_to? :add_options
		end.parse!(args)
		
		inductor.induct(args)
	end
end