require 'chef-workflow/support/general'
require 'chef-workflow/support/ip'
require 'chef-workflow/support/vagrant'
require 'chef-workflow/support/ec2'
require 'chef-workflow/support/knife'
require 'chef-workflow/support/scheduler'
require 'chef/config'
require 'fileutils'

namespace :chef do
  namespace :clean do
    desc "Clean up the ip registry for chef-workflow"
    task :ips do
      IPSupport.singleton.reset
      IPSupport.singleton.write
    end

    desc "Clean up the temporary chef configuration for chef-workflow"
    task :knife do
      FileUtils.rm_rf(KnifeSupport.singleton.chef_config_path)
      FileUtils.rm_f(KnifeSupport.singleton.knife_config_path)
    end

    desc "Clean up the machines that a previous chef-workflow run generated"
    task :machines do
      if File.exist?(KnifeSupport.singleton.knife_config_path)
        Chef::Config.from_file(KnifeSupport.singleton.knife_config_path)
        s = Scheduler.new(false)
        s.serial = true
        s.force_deprovision = true
        s.teardown(%w[chef-server])
        s.write_state
      end
    end
  end

  desc "Clean up the entire chef-workflow directory and machines"
  task :clean => [ "chef:clean:machines", "chef_server:destroy" ] do
    EC2Support.singleton.destroy_security_group
    FileUtils.rm_rf(GeneralSupport.singleton.workflow_dir)
  end
end
