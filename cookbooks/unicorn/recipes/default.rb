gem_package "unicorn" do
  action :upgrade
  version node[:unicorn][:version]
end

directory "/etc/unicorn" do
  owner "app"
  group "app"
  mode 0755
end

directory "/tmp/unicorn" do
  owner "app"
  group "app"
  mode 0755
end

counter = 0

node[:active_applications].each do |name, config|
  next unless node[:rails][:app_server] == 'unicorn'

  app_root = "/u/apps/#{name}"

  defaults = Mash.new({
    :pid_path => "#{app_root}/shared/pids/unicorn.pid",
    :worker_count => node[:unicorn][:worker_count],
    :timeout => node[:unicorn][:timeout],
    :socket_path => "/tmp/unicorn/#{name}.sock",
    :backlog_limit => 1,
    :master_bind_address => '0.0.0.0',
    :master_bind_port => "37#{counter}00",
    :worker_listeners => true,
    :worker_bind_address => '127.0.0.1',
    :worker_bind_base_port => "37#{counter}01",
    :debug => false,
    :binary_path => config[:rack_only] ? "#{node[:ruby_bin_path]}/unicorn" : "#{node[:ruby_bin_path]}/unicorn_rails",
    :env => 'production',
    :app_root => app_root,
    :enable => true,
    :config_path => "#{app_root}/current/config/unicorn.conf.rb"
  })
  
  config = defaults.merge(Mash.new(config))
  
  runit_service "unicorn-#{name}" do
    template_name "unicorn"
    cookbook "unicorn"
    options config
  end
    
  service "unicorn-#{name}" do
    action config[:enable] ? [:enable, :start] : [:disable, :stop]
  end

  counter += 1
end
