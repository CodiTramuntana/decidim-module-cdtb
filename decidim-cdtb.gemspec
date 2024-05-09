# frozen_string_literal: true

require_relative "lib/decidim/cdtb/version"

Gem::Specification.new do |spec|
  spec.name = "decidim-cdtb"
  spec.version = Decidim::Cdtb::VERSION
  spec.authors = ["Oliver Valls"]
  spec.email = ["199462+tramuntanal@users.noreply.github.com"]

  spec.summary = "CodiTramuntana's Decidim Toolbelt (cdtb)."
  spec.description = "A gem to help managing Decidim applications."
  spec.homepage = "https://github.com/CodiTramuntana/decidim-module-cdtb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.7"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "decidim", Decidim::Cdtb::DECIDIM_MIN_VERSION
  spec.add_dependency "rails", ">= 6"
  spec.add_dependency "ruby-progressbar"

  spec.add_development_dependency "decidim-dev", Decidim::Cdtb::DECIDIM_MIN_VERSION
  spec.add_development_dependency "faker"
  spec.metadata["rubygems_mfa_required"] = "true"
end
