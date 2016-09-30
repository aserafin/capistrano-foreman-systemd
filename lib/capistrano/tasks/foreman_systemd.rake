namespace :foreman_systemd do
  desc <<-DESC
        Setup foreman configuration

        Configurable options are:

          set :foreman_systemd_roles, :all
          set :foreman_systemd_export_format, 'upstart'
          set :foreman_systemd_export_path, '/etc/init'
          set :foreman_systemd_flags, ''
          set :foreman_systemd_target_path, release_path
          set :foreman_systemd_app, -> { fetch(:application) }
          set :foreman_systemd_concurrency, 'web=2,worker=1' # default is not set
          set :foreman_systemd_log, -> { shared_path.join('log') }
          set :foreman_systemd_port, 3000 # default is not set
          set :foreman_systemd_user, 'www-data' # default is not set
    DESC

  task :setup do
    invoke :'foreman_systemd:export'
    invoke :'foreman_systemd:enable'
    invoke :'foreman_systemd:start'
  end

  desc 'Enables service in systemd'
  task :enable do
    on roles fetch(:foreman_systemd_roles) do
      sudo :systemctl, "enable #{fetch(:foreman_systemd_app)}.target"
    end
  end

  desc 'Disables service in systemd'
  task :disable do
    on roles fetch(:foreman_systemd_roles) do
      sudo :systemctl, "disable #{fetch(:foreman_systemd_app)}.target"
    end
  end


  desc 'Export the Procfile to another process management format'
  task :export do
    on roles fetch(:foreman_systemd_roles) do |server|
      execute :mkdir, '-p', fetch(:foreman_systemd_export_path) unless test "[ -d #{fetch(:foreman_systemd_export_path)} ]"
      within fetch(:foreman_systemd_target_path, release_path) do

        options = {
          app: fetch(:foreman_systemd_app),
          log: fetch(:foreman_systemd_log)
        }
        options[:concurrency] = fetch(:foreman_systemd_concurrency) if fetch(:foreman_systemd_concurrency)
        options[:concurrency] = server.properties.foreman_systemd_concurrency if server.properties.foreman_systemd_concurrency
        options[:port] = fetch(:foreman_systemd_port) if fetch(:foreman_systemd_port)
        options[:user] = fetch(:foreman_systemd_user) if fetch(:foreman_systemd_user)

        sudo :foreman, 'export', fetch(:foreman_systemd_export_format), fetch(:foreman_systemd_export_path),
          options.map{ |k, v| "--#{k}='#{v}'" }, fetch(:foreman_systemd_flags)
      end
    end
  end

  desc 'Start the application services'
  task :start do
    on roles fetch(:foreman_systemd_roles) do
      sudo :systemctl, "start #{fetch(:foreman_systemd_app)}.target"
    end
  end

  desc 'Stop the application services'
  task :stop do
    on roles fetch(:foreman_systemd_roles) do
      sudo :systemctl, "stop #{fetch(:foreman_systemd_app)}.target"
    end
  end

  desc 'Restart the application services'
  task :restart do
    on roles fetch(:foreman_systemd_roles) do
      sudo :systemctl, "restart #{fetch(:foreman_systemd_app)}.target"
    end
  end

end

namespace :load do
  task :defaults do
    set :foreman_systemd_roles, :all
    set :foreman_systemd_export_format, 'systemd'
    set :foreman_systemd_export_path, '/etc/systemd/system'
    set :foreman_systemd_flags, ''
    set :foreman_systemd_app, -> { fetch(:application) }
    set :foreman_systemd_log, -> { shared_path.join('log') }
  end
end
