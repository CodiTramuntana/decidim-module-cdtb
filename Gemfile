# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in decidim-cdtb.gemspec
gemspec

require_relative "lib/decidim/cdtb/version"

gem "uri", ">= 0.13.1"

group :development, :test do
  gem "bootsnap", require: false
  gem "byebug", platform: :mri
  gem "decidim", Decidim::Cdtb::DECIDIM_MIN_VERSION,
      { github: "CodiTramuntana/decidim", branch: "release/0.28-stable", require: true }.freeze
  gem "faker"
  gem "letter_opener_web"
  gem "listen"
end

group :development do
  gem "rake", "~> 13.0"
  gem "rubocop", "~>1.50.0"
end

group :test do
  gem "rspec", "~> 3.0"
  gem "sqlite3", "~> 1.4"
end
