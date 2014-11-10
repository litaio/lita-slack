Gem::Specification.new do |spec|
  spec.name          = "lita-slack"
  spec.version       = "0.1.2"
  spec.authors       = ["Ken J."]
  spec.email         = ["kenjij@gmail.com"]
  spec.description   = %q{Lita adapter for Slack.}
  spec.summary       = %q{Lita adapter for Slack.}
  spec.homepage      = "https://github.com/kenjij/lita-slack"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "adapter" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 2.7"
  spec.add_runtime_dependency "lita-slack-handler", ">= 0.2.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
