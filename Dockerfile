FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir -p /mn_utils_gem/lib/mn_utils_gem
WORKDIR /mn_utils_gem
COPY mn_utils_gem.gemspec /mn_utils_gem/mn_utils_gem.gemspec
COPY Gemfile /mn_utils_gem/Gemfile
COPY Gemfile.lock /mn_utils_gem/Gemfile.lock
COPY lib/mn_utils_gem/version.rb /mn_utils_gem/lib/mn_utils_gem
RUN bundle install
COPY . /mn_utils_gem
