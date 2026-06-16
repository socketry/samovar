# frozen_string_literal: true

require_relative "lib/samovar/version"

Gem::Specification.new do |spec|
	spec.name = "samovar"
	spec.version = Samovar::VERSION
	
	spec.summary = "Samovar is a flexible option parser excellent support for sub-commands and help documentation."
	spec.authors = ["Samuel Williams", "Gabriel Mazetto", "Gerhard Schlager"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/ioquatix/samovar"
	
	spec.metadata = {
		"documentation_uri" => "https://ioquatix.github.io/samovar/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/ioquatix/samovar.git",
	}
	
	spec.files = Dir.glob(["{context,lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "console", "~> 1.0"
end
