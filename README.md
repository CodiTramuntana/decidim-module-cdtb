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

### Fix nicknames

In a previous version than Decidim v0.25 a validation to the `Decidim::User.nickname` was added with a migration to fix existing nicknames. But the migration was only taking into acocunt managed (impersonated) users.

This task iterates (with `find_each`) over all non managed users and nicknamizes the nickname.

To execute the task run:

```
bin/rake cdtb:fix_nicknames
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

### Detect spam

To detect spam in Decidim.

#### Detect spam users
This rake task export a .csv with a list of suspicious users.

- `bin/rake cdtb:spam:users[host]`

Examples:
`bin/rake cdtb:spam:users[boi]` --> find users in organization with "boi" string in the host name.
`bin/rake cdtb:spam:users` --> find all users in all organizations.

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
