# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in decidim-cdtb.gemspec
gemspec

require_relative "lib/decidim/cdtb/version"

# temporal solution while gems embrace new psych 4 (the default in Ruby 3.1) behavior.
gem "psych", "< 4"

group :development, :test do
  gem "bootsnap", require: false
  gem "byebug", platform: :mri
  gem "decidim", Decidim::Cdtb::DECIDIM_MIN_VERSION, require: true
  gem "letter_opener_web"
  gem "listen"
end

group :development do
  gem "rake", "~> 13.0"
  gem "rubocop"
end

group :test do
  gem "rspec", "~> 3.0"
  gem "sqlite3", "~> 1.4"
end
