
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mn_utils_gem/version"

Gem::Specification.new do |spec|
  spec.name          = "mn_utils_gem"
  spec.version       = MnUtilsGem::VERSION
  spec.authors       = ["Shamim Mirzai"]
  spec.summary       = "Mumsnet utils gem for microservices"
  spec.homepage      = "https://github.com/mumsnet/mn_utils_gem"

  # Specify which files should be added to the gem when it is released.
  spec.files         = [
      'lib/mn_utils_gem.rb',
      'lib/mn_utils_gem/version.rb',
      'lib/mn_utils_gem/site_action.rb',
      'lib/mn_utils_gem/gui.rb',
      'lib/mn_utils_gem/transactional_email.rb',
      'lib/mn_utils_gem/sso.rb',
  ]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'gelf'
  spec.add_runtime_dependency 'aws-sdk-cloudwatch'
  spec.add_runtime_dependency 'aws-sdk-sqs'
  spec.add_runtime_dependency 'request_store'
  spec.add_runtime_dependency 'httparty'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'redis'
  spec.add_runtime_dependency 'semian'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
