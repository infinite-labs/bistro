require 'ilabs/bistro'
require 'ilabs/bistro/induct'

def main
	ILabs::Bistro.induct(TestInductor)
end

class TestInductor < ILabs::Bistro::Inductor
	def add_option_parser_flags(opts)
		opts.on('-m', '--magic VALUE', 'Sets the magic value to VALUE') do |v|
			@magic = v
		end
	end
	
	def platform
		"net.infinite-labs.test"
	end
	
	def update_metadata_for_artifact(a)
		a.meta['Magic'] = @magic if @magic
	end	
end

main
