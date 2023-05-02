# Decidim::Cdtb

This is CodiTramuntana's Decidim Toolbelt (cdtb), a gem to help managing Decidim applications.


## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add decidim-cdtb

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install decidim-cdtb

## Usage

### Rake tasks

#### Organizations information

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

#### Fix nicknames

In a previous version than Decidim v0.25 a validation to the `Decidim::User.nickname` was added with a migration to fix existing nicknames. But the migration was only taking into acocunt managed (impersonated) users.

This task iterates (with `find_each`) over all non managed users and nicknamizes the nickname.

To execute the task run:

```
bin/rake cdtb:fix_nicknames
```

#### Migrate ActiveStorage service from S3 to local

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

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/decidim-cdtb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/decidim-cdtb/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Decidim::Cdtb project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/decidim-cdtb/blob/master/CODE_OF_CONDUCT.md).
