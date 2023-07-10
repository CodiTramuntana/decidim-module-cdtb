# frozen_string_literal: true

module Decidim
  module Cdtb
    module Upgrades
      # Invokes rails to install gem migrations
      #
      class InstallGemMigrationsStep
        # Pass +gem_names+ to define from which gems to install migrations.
        def install!(gem_names)
          cmd= "#{Rails.root.join("bin/rails")} railties:install:migrations"
          env_vars= "FROM=#{gem_names.join(",")}"
          `#{cmd} #{env_vars}`
        end
      end
    end
  end
end
