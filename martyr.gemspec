# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'martyr/version'

Gem::Specification.new do |spec|
  spec.name          = "martyr"
  spec.version       = Martyr::VERSION
  spec.authors       = ["Amit Aharoni"]
  spec.email         = ["amit.sites@gmail.com"]

  spec.summary       = %q{Add data mart and pivoting functionality to Active Record models}
  spec.description   = %q{A multi-dimensional semantic layer on top of ActiveRecord that allows running pivot table queries and rendering them as CSV, HTML, or KickChart-ready hashes. Supports time dimensions, cohort analysis, custom rollups, and drilling through to the underlying ActiveRecord objects.}
  spec.homepage      = "https://github.com/vaharoni/martyr"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "sqlite3", "~> 1.3"
  spec.add_development_dependency "activerecord", "~> 4.2"
  spec.add_development_dependency "chinook_database", "~> 0.1"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "pry-byebug", "~> 3.3"

  spec.add_runtime_dependency "activesupport", "~> 4.2"
  spec.add_runtime_dependency "activemodel", "~> 4.2"
end
