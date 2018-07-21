# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require 'pp'
require './_vagrantsupport/TestBedConfig.rb'
require './_vagrantsupport/VMDefFactory.rb'

#-------------------------------------------------------
# Script Execution Start
#-------------------------------------------------------

#
# Read the default configuration
#
default_config_path = "#{File.dirname(__FILE__)}/testbed-defaults.yaml"

if not File.file?(default_config_path)
  raise Vagrant::Errors::VagrantError.new, "Cannot find default configuration at #{default_config_path}"
end

default_config = YAML.load_file(default_config_path)

#
# Read the userland configuration, if any
#
user_config_path = "#{File.dirname(__FILE__)}/testbed.yaml"
if ENV["TESTBED_CONF"]
  user_config_path = ENV["TESTBED_CONF"]
  if not File.file?(user_config_path)
    raise Vagrant::Errors::VagrantError.new, "Cannot find user configuration at #{user_config_path}"
  else
    puts "Loading testbed user configuration from #{user_config_path}"
  end
end

user_config = {}
if File.file?(user_config_path)
  begin
    user_config = YAML.load_file(user_config_path)
    if not user_config.is_a?(Hash)
      user_config = {}
    end
  rescue Exception => e
    raise Vagrant::Errors::VagrantError.new, "Could not parse #{user_config_path}, #{e.message}"
  end
end

testBedConfig = TestBedConfig.new default_config, user_config

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  factory = VMDefFactory.new(config)

  testBedConfig.vms().each do |vmspec|
    factory.create_vm(name: vmspec["name"],
      vm_config: vmspec["vm_config"])
  end

end