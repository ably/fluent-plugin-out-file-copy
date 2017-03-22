# -*- coding:utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Matthew O'Riorda"]
  gem.email         = ["matt@ably.io"]
  gem.description   = %q{Fluent output plugin to handle output directory by interpolation}
  gem.summary       = %q{Fluent output plugin to handle output directory by interpolation}
  gem.homepage      = "https://github.com/ably/fluent-plugin-out-file-copy"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-out-file-copy"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.1"
  gem.add_development_dependency "fluentd"
  gem.add_runtime_dependency "fluentd"
end
