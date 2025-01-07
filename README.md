# Decidim::Cdtb

This is CodiTramuntana's Decidim Toolbelt (cdtb), a gem to help managing Decidim applications.


## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add decidim-cdtb
    $ bundle install

Install CI tests on your app with:

    $ bin/rails generate cdtb:validate_migrations_ci


## Usage

### Organizations information

Returns information regarding the organizations in a multitenant installation that match a search term ignorecase.


The following will return all the attributes for all organizations that contain the "vila" term in its host name:

```
bin/rake cdtb:org_by_host_like[vila,true]
```

With the `full` argument set to `true` will return the most relevant attributes:

```
bin/rake cdtb:org_by_host_like[vila]
>>> Organization [1] Sant Boi de Llobregat:
host: localhost, time_zone: Madrid, locales: ca + [ca, es, oc], available authorizations: [postal_letter, members_picker_authorization_handler]
```


### Anonymize production dump

Anonymize rake task was taken from https://github.com/AjuntamentdeBarcelona/decidim-barcelona

Available rake tasks:

- `bin/rake cdtb:anonymize:check` allows you to check if you can anonymize production dump
- `bin/rake cdtb:anonymize:all` anonymizes whole production dump (without proposals)
- `bin/rake cdtb:anonymize:users` anonymizes users
- `bin/rake cdtb:anonymize:proposals` anonymizes proposals
- `bin/rake cdtb:anonymize:user_groups` anonymizes user groups
- `bin/rake cdtb:anonymize:system_admins` anonymizes system admins
- `bin/rake cdtb:anonymize:paper_trail` anonymizes paper trails

### Fix YouTube embeds for Decidim v0.28

Fixes YouTube embeds to Decidim v0.28 format in different places, which at the moment are:

- Decidim::Meetings::Meeting
- Decidim::Debates::Debate
- Decidim::Pages::Page
- Decidim::Assembly
- Decidim::ParticipatoryProcess

```
bin/rake cdtb:embeds:fix_youtube
```


### Migrate ActiveStorage service from S3 to local

To migrate from S3 to local storage, the identified steps will be:

1. Download the assets to a temporary directory:
    `aws s3 sync s3://bucket-name tmp/storage/`
2. Move the downloaded assets into the local storage directory doing the sharding:
    `bin/rake cdtb:s3_to_local:do_sharding`
3. Update all blobs to use the local service
    `bin/rake cdtb:s3_to_local:set_local_service_on_blobs`
4. Clean the cache:
    `bin/rake cache:clear`
5. Restart the Rails server

### Spam & bots

Spam and bots are daily menaces in the current Internet. Decidim is not an exception, and is affected by both security concerns and performance.

#### Bad bots and crawlers

Decidim is already bundled with Rack::Attack but it lacks some features like IP banning or throttling by forwarded IP (useful when Decidim is behind a proxy). CDTB by default enables Rack::Attack with these features.

Four ENV variables exist to configure its behaviour:

- CDTB_RACK_ATTACK_DISABLED: Set to 1 to disable CDTB's Rack:Attack.
- RACK_ATTACK_THROTTLE_LIMIT: The max. allowed number of requests during the period. Defaults to 30.
- RACK_ATTACK_THROTTLE_PERIOD: The period in seconds. Defaults to 60.
- RACK_ATTACK_BLOCKED_IPS: A comma separated list of blocked IPs or subnets (in the form 1.2.3.0/32).


Available rake tasks to help analize crawlers:

- `bin/rake cdtb:logs:num_rq_per_ip` Counts the number of requests for each IP in the logs. Accepts a logfile param, it must be in log/.

#### Detect spam users

Detects users susceptible of being spammers. It can run on all organizations or be scoped to a single organization by passing the organization ID as the rake task parameter.

This rake task export a .csv with a list of all the searched users. A column indicates if each user is suspicious of being a spammer or not.
The columns in the CSV are: "ID, "Is suspicious?", "Name", "Email", "Nickname", "Personal URL", "About"

Examples:

`bin/rake cdtb:spam:users[org_id]` --> find users in organization with an id.
`bin/rake cdtb:spam:users` --> find all users in all organizations.

To set custom words in the rake, you can override it with an initalizer:

```
Decidim::Cdtb.configure do |config|
  config.spam_words = ENV["CDTB_SPAM_WORDS"]&.split(",")
end
```

### Users

Tasks related with users.

### Fix nicknames

In a previous version than Decidim v0.25 a validation to the `Decidim::User.nickname` was added with a migration to fix existing nicknames. But the migration was only taking into account managed (impersonated) users.

This task iterates (with `find_each`) over all non managed users and nicknamizes the nickname.

To execute the task run:

```
bin/rake cdtb:users:fix_nicknames
```

#### Remove users

You can delete users through a CSV with the user ID and a reporter user mailer. The purpose is to be able to eliminate potentially spammy users.

This task reports and hide the user's comments, blocks the user, and finally deletes the user.

The CSV will have a header and one column with the user ID.

To execute the task run:

```
bundle exec rake cdtb:users:remove[spam_users.csv, reporter_user@example.org]
```

### Participatory Spaces / Add content blocks 

You can add content blocks to a participatory spaces with the content block name (manifest_name).
This rake task affects spaces in all organizations.

Content block manifest names list:

```
basic_only_text
image_text_cta
metadata
hero
participatory_processes
html_2
main_data
title
cta
highlighted_proposals
how_to_participate
html_1
related_documents
stats
html
slider
footer_sub_hero
global_menu
sub_hero
highlighted_content_banner
highlighted_processes
highlighted_assemblies
highlighted_regulations
upcoming_meetings
extra_data
highlighted_meetings
highlighted_results
metrics
related_assemblies
announcement
social_networks_metadata
related_processes
highlighted_posts
last_activity
```

Spaces supported:

- Decidim::ParticipatoryProcess
- Decidim::Assembly

To execute the task run:

```
bundle exec rake cdtb:participatory_spaces:add_content_blocks[manifest_name]
```

You can add multiple manifest names with this format:

```
bundle exec rake cdtb:participatory_spaces:add_content_blocks[['manifest_name_one manifest_name_two']]
```

Some examples
```
bundle exec rake cdtb:participatory_spaces:add_content_blocks[extra_data]

bundle exec rake cdtb:participatory_spaces:add_content_blocks[['extra_data related_documents']]

```

### Upgrades:

#### Upgrade modules

Upgrades the gems with engines in them. All, Decidim modules and standard Rails engines.

TO-DO To be finished

#### Validate migrations

Validates that migrations from all gems in the Gemfile have already been installed.

```
bin/rake cdtb:upgrades:validate_migrations
```

See the [Installation](#installation) chapter to install a GitHub Action on your app that will run this validation on your CI.

TO-DO also check that all migrations have been executed and the schema.rb does not change

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Run tests

Node 16.9.1 is required!

Create a dummy app:

```bash
bin/rails decidim:generate_external_test_app
```

And run tests:

```bash
bundle exec rspec spec
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CodiTramuntana/decidim-cdtb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/CodiTramuntana/decidim-cdtb/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Decidim::Cdtb project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/CodiTramuntana/decidim-cdtb/blob/master/CODE_OF_CONDUCT.md).
