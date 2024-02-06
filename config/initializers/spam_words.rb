# frozen_string_literal: true

Decidim::Cdtb::Spam::UserSpamDetector.configure do |config|
  config.spam_words = %w[viagra sex game free crypto crack xxx luck girls vip download]

  config.spam_regexp = Regexp.union(config.spam_words)
end
