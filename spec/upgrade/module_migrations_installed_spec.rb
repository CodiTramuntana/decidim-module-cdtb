# frozen_string_literal: true

RSpec.describe Decidim::Cdtb do
  it "has all migrations from all decidim modules installed" do
    all_railties= Rails.application.migration_railties
    decidim_railties= all_railties.select { |railtie| railtie.railtie_name.starts_with?("decidim") }
    decidim_modules_names= decidim_railties.map(&:railtie_name)

    cmd= "#{Rails.root.join("bin/rails")} railties:install:migrations"
    env_vars= "FROM=#{decidim_modules_names.join(",")}"
    output= `#{cmd} #{env_vars}`

    expect(output).not_to include("Copied migration")
  end
end
