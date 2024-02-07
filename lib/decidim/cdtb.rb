# frozen_string_literal: true

require_relative "cdtb/version"
require_relative "cdtb/engine"
require_relative "cdtb/tasks"

module Decidim
  # Cdtb configuration
  module Cdtb
    include ActiveSupport::Configurable

    class Error < StandardError; end

    config_accessor :spam_words do
      %w[viagra sex game free crypto crack xxx luck girls vip download]
    end
  end
end
