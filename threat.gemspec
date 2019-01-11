
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "threat/version"

Gem::Specification.new do |spec|
  spec.name          = "threat"
  spec.version       = Threat::VERSION
  spec.authors       = ["Josh Hawkins"]
  spec.email         = ["hawkins@users.noreply.github.com"]

  spec.summary       = "A multi-threaded HTTP client catered for high-volume, high-performance needs with rate-limiting and asynchrony baked in."
  spec.homepage      = "https://github.com/hawkins/threat"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.12"

  spec.add_runtime_dependency "httpclient", "~> 2.7"
end
