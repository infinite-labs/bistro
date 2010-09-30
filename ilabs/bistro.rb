require 'rubygems'
require 'json'
require File.join(File.dirname(__FILE__), 'uuid.rb')

module ILabs; end
module ILabs::Bistro

	class Artifact
		def self.at(p)
			return nil unless p.subpath('ArtifactInfo.json').exist?
			self.new p
		end
		
		def initialize(p)
			p = Path.new p if p.kind_of? String
			raise "#{p} not a(n existing?) directory." unless p.directory?
			
			@path = p
			
			@meta = {}
			if meta_file.exist?
				meta_file.open('r') do |file|
					@meta = JSON.load(file)
					raise "ArtifactInfo.json does not contain a JSON object (Hash)." unless @meta.kind_of? Hash
				end
			end
		end
		
		def meta_file
			@path.subpath 'ArtifactInfo.json'
		end
		
		attr_reader :path, :meta
		
		def update
			meta['State'] = UUID.create_random.to_s
		end
		
		def save(options = {})
			options[:update] = true if options[:update].nil?
			update if options[:update]
			
			meta_file.open('w') do |file|
				JSON.dump(meta, file)
			end
		end
		
		def updated_since_state? s
			not s or @meta['State'] != s
		end
	end
	
	class Path
		def initialize(path, relative_to='.')
			path = path.join('/') if path.kind_of? Array
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
		
		def subpath(*args)
			self.class.new join(*args)
		end
		
		def starting_from(other)
			raise unless other.parent_of? self
			new_pc = path_components.dup
			new_pc[0, other.path_components.length] = []
			Path.new new_pc
		end
		
		def method_missing(name, *args)
			me = to_s
			new_args = [me] + args
			File.send name, *new_args
		end
		
		def open(mode)
			return File.open(to_s, mode) unless block_given?
			
			File.open(to_s, mode) do |file|
				yield file
			end
		end
	end
	
	class PathUtils
		def initialize(fu)
			@fu = fu
		end
		
		def self.for(fu)
			return fu if fu.kind_of? PathUtils
			new fu
		end
		
		def method_missing(name, *args)
			new_args = []
			args.each do |a|
				if a.kind_of? Path
					new_args << a.to_s
				else
					new_args << a
				end
			end
			
			@fu.send name, *new_args
		end
	end
	
	class Vault
		def initialize(p)
			p = Path.new p if p.kind_of? String
			raise "#{p} not a(n existing?) directory." unless p.directory?
			
			@path = p
			@meta = {}
			if meta_file.exist?
				meta_file.open('r') do |file|
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
			path = a.path.starting_from(self.path).to_s
			unless @meta['Artifacts'].include? path
				@meta['Artifacts'] << path
				save
			end
		end
		
		def delete_artifact(a)
			path = a.path.starting_from(self.path).to_s
			if @meta['Artifacts'].include? path
				@meta['Artifacts'].delete path
				save
			end
		end
		
		def artifacts
			x = []
			@meta['Artifacts'].each do |artifact_path|
				a = Artifact.new artifact_path, path.to_s
				x << a
			end
			x
		end
		
		def meta_file
			path.subpath 'VaultInfo.json'
		end
		
		def save
			meta_file.open('w') do |file|
				JSON.dump(@meta, file)
			end
		end
		
	end
	
end
