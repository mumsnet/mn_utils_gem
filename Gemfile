source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in mn_utils_gem.gemspec
gemspec

gem 'gelf'
gem 'aws-sdk-cloudwatch'
gem 'request_store'

group :development, :test do
  gem 'rspec', require: false
  gem 'rspec-rails', require: false
end
