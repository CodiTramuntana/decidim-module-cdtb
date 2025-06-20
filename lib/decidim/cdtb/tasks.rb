# frozen_string_literal: true

require "decidim/cdtb/tasks_utils"
require "decidim/cdtb/task"
require "decidim/cdtb/fixes/nickname_fixer"
require "decidim/cdtb/fixes/you_tube_embeds_fixer"
require "decidim/cdtb/users/remover"
require "decidim/cdtb/multitenants/org_by_host_like"
require "decidim/cdtb/participatory_spaces/add_content_blocks"
require "decidim/cdtb/participatory_spaces/move_images_to_content_block"
require "decidim/cdtb/spam/spam_users_detector"
require "decidim/cdtb/storage/local_sharding"
require "decidim/cdtb/storage/set_local_on_blobs"
require "decidim/cdtb/upgrades/validate_migrations_task"
