# frozen_string_literal: true

module Decidim
  module Cdtb
    # This module's engine
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Cdtb

      initializer "psych.tmp.fix" do |_app|
        # Workaround for https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif
        Rails.application.config.active_record.use_yaml_unsafe_load = true
      end
    end
  end
end
