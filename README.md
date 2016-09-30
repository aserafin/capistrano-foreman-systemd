# Capistrano::ForemanSystemd

This is heavily based on the [capistrano-foreman](https://github.com/koenpunt/capistrano-foreman) gem but it only targets `systemd` (default init system for Ubuntu since 16.04).
It works best with [foreman-systemd](https://github.com/aserafin/foreman) (fork of 0.78 version of [foreman](https://github.com/ddollar/foreman) gem).

## Installation

```ruby
gem 'capistrano', '~> 3.1'
gem 'capistrano-foreman-systemd'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-foreman-systemd

## Usage

Require in `Capfile`:

```ruby
require 'capistrano/foreman_systemd'
```

Export Procfile to process management format (defaults to upstart) and restart the application services:

    $ cap foreman_systemd:setup
    $ cap foreman_systemd:start

Configurable options, shown here with defaults:

```ruby
set :foreman_systemd_roles, :all
set :foreman_systemd_export_format, 'upstart'
set :foreman_systemd_export_path, '/etc/init'
set :foreman_systemd_flags, "--root=#{current_path}" # optional, default is empty string
set :foreman_systemd_target_path, release_path
set :foreman_systemd_app, -> { fetch(:application) }
set :foreman_systemd_concurrency, 'web=2,worker=1' # optional, default is not set
set :foreman_systemd_log, -> { shared_path.join('log') }
set :foreman_systemd_port, 3000 # optional, default is not set
set :foreman_systemd_user, 'www-data' # optional, default is not set
```

See [exporting options](http://ddollar.github.io/foreman/#EXPORTING) for an exhaustive list of foreman options.

### Tasks

This gem provides the following Capistrano tasks:

* `foreman_systemd:setup` exports the Procfile and starts application services
* `foreman_systemd:export` exports the Procfile to process management format
* `foreman_systemd:enable` enables the application in systemd
* `foreman_systemd:disable` disables the application in systemd
* `foreman_systemd:restart` restarts the application services
* `foreman_systemd:start` starts the application services
* `foreman_systemd:stop` stops the application services

### User permissions

Commands have to be executed with `root` or user with `sudo` writes because `foreman:setup` creates files in `/etc/systemd/system` directory.

## Example

A typical setup would look like the following:

Have a group-writeable directory under `/etc/init` for the group `deploy` (in this case I call it `sites`) to store the init scripts:

```bash
sudo mkdir /etc/init/sites
sudo chown :deploy /etc/init/sites
sudo chmod g+w /etc/init/sites
```

And the following configuration in `deploy.rb`:

```ruby
# Set the app with `sites/` prefix
set :foreman_app, -> { "sites/#{fetch(:application)}" }

# Set user to `deploy`, assuming this is your deploy user
set :foreman_user, 'deploy'

# Set root to `current_path` so exporting only have to be done once.
set :foreman_flags, "--root=#{current_path}"
```

Setup your init scripts by running `foreman:setup` after your first deploy.
From this moment on you only have to run `foreman:setup` when your `Procfile` has changed or when you alter the foreman deploy configuration.

Finally you have to instruct Capistrano to run `foreman:restart` after deploy:

You can control which process runs on which servers using server variable `foreman_systemd_concurrency`:

```ruby
server '123.123.123.1', { roles: [:web], foreman_systemd_concurrency: 'web=1,sidekiq=1' }
server '123.123.123.1', { roles: [:web], foreman_systemd_concurrency: 'web=1,sidekiq=0' }
```

Finally

```ruby
# Hook foreman restart after publishing
after :'deploy:publishing', :'foreman:restart'
```

## Notes

When using `rbenv`, `rvm`, `chruby` and/or `bundler` don't forget to add `foreman` to the bins list:

```ruby
fetch(:rbenv_map_bins, []).push 'foreman'
fetch(:rvm_map_bins, []).push 'foreman'
fetch(:chruby_map_bins, []).push 'foreman'
fetch(:bundle_bins, []).push 'foreman'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request