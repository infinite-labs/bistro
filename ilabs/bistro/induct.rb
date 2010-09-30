require File.join(File.dirname(File.dirname(__FILE__)), 'bistro.rb')
require 'optparse'
require 'fileutils'

module ILabs; end
module ILabs::Bistro
	
	class Inductor
		def add_option_parser_flags(opts)
		end
		
		attr_accessor :options
		
		def source_path
			options[:source_path]
		end
		
		def induct(vault)
			raise "No source directory specified" unless options[:source_path]
			a = vault.induct_into self.vault_id, self.files_to_copy
			self.update_metadata_for_artifact(a)
			a.save
		end
		
		def files_to_copy()
			[source_path.subpath '.']
		end
		
		def identifier
			return options[:identifier] || source_path.basename
		end
		
		def vault_id
			return "#{platform}/#{identifier}"
		end
		
		def update_metadata_for_artifact(a)
		end
		
		def platform
			raise "Unimplemented"
		end
	end
	
	def self.induct(inductor, args = nil)
		inductor = inductor.new if inductor.respond_to? :new
		
		args = ARGV.dup if args.nil?
		options = {}
		OptionParser.new do |opts|
			opts.on('-V', '--vault PATH', 'The path to the vault to induct in') do |p|
				p = Path.new(p)
				raise "Not a(n existing?) directory: #{p}" unless p.directory?
				options[:vault_path] = p
			end
			
			opts.on('-d', '--induct PATH', 'The path of the directory to induct from') do |p|
				p = Path.new(p)
				raise "Not a(n existing?) directory: #{p}" unless p.directory?
				options[:source_path] = p
			end
			
			opts.on('-i', '--identifier IDENTIFIER', 'The identifier to use for this artifact.') do |ident|
				options[:identifier] = ident
			end
			
			opts.on('-D', '--debug', 'Shows debug logging.') do |debug|
				ILabs::Bistro.debug = debug
			end
			
			inductor.add_option_parser_flags(opts)
		end.parse!(args)
		
		inductor.options = options
		v = Vault.new(options[:vault_path])
		inductor.induct(v)
	end
	
	class Vault
		def induct_into(ident, files_to_copy, fu = nil)
			fu ||= FileUtils::Verbose
			fu = PathUtils.for(fu)
			
			artifact_path = path.subpath(ident)
			raise "An item with identifier #{ident} already exists in this vault!" if artifact_path.directory?
			
			fu.mkdir_p artifact_path
			files_to_copy.each do |f|
				fu.cp_r f, artifact_path
			end
			
			a = Artifact.new artifact_path
			self.add_artifact a
			a
		end
	end
end

