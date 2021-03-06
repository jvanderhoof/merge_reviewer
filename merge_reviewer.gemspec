# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'merge_reviewer/version'

Gem::Specification.new do |spec|
  spec.name          = "merge_reviewer"
  spec.version       = MergeReviewer::VERSION
  spec.authors       = ["Jason Vanderhoof"]
  spec.email         = ["jvanderhoof@gmail.com"]
  spec.summary       = %q{Get complexity and duplication for  a single file, or all of them.}
  spec.description   = %q{Gem that simplifies the process of getting complexity and duplication for  a single file.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'flog'
  spec.add_dependency 'flay'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
