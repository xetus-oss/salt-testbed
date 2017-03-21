# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

class ConfigParam
  def initialize(config_var_name, env_var_name, default_val)
    @config_var_param   = config_var_name
    @env_var_name = env_var_name
    @default  = default_val
  end
  def config_var_param
    @config_var_param
  end
  def env_var_name
    @env_var_name
  end
  def default
    @default
  end
end

#
# Define the various configuration parameters and their defaults
#
config_params = []
config_params << ConfigParam.new("salt_version", "SALT_VERSION", "git v2016.11.2")
config_params << ConfigParam.new("salt_development", "SALT_DEVELOPMENT", false)
config_params << ConfigParam.new("minion_mem", "MINION_MEM", 2048)
config_params << ConfigParam.new("master_mem", "MASTER_MEM", 512)
config_params << ConfigParam.new("bigminion_mem", "BIGMINION_MEM", 4096)
config_params << ConfigParam.new("use_master_ip", "USE_MASTER_IP", "192.168.51.2")
config_params << ConfigParam.new("use_bridged_network", "USE_BRIDGED_NETWORK", false)
config_params << ConfigParam.new("bridge_interface", "BRIDGE_INTERFACE", nil)
config_params << ConfigParam.new("vm_name_prefix", "VM_NAME_PREFIX", nil)
config_params << ConfigParam.new("forward_master_ports", "FORWARD_MASTER_PORTS", false)
config_params << ConfigParam.new("multi_master", "MULTI_MASTER", false)
config_params << ConfigParam.new("masters_are_minions", "MASTERS_ARE_MINIONS", false)

# TODO: Make it ok if this file is empty
yaml_config_file = "#{File.dirname(__FILE__)}/testbed.yml"
yaml_config = {}

if File.file?(yaml_config_file)
  yaml_config = YAML.load_file(yaml_config_file)
  if not yaml_config
    yaml_config = {}
    puts "Unable to ready any values from #{yaml_config_file}, it will be ignored"
  end
end

testbed_config =  {}
config_params.each { |cp|
  if ENV[cp.env_var_name]
    testbed_config[cp.config_var_param] = ENV[cp.env_var_name]
  elsif yaml_config.key?(cp.config_var_param)
    testbed_config[cp.config_var_param] = yaml_config[cp.config_var_param]
  else
    testbed_config[cp.config_var_param] = cp.default
  end
}

if testbed_config['use_bridged_testbed'] and ARGV[0] == "up"
  puts "!! Using a bridged testbed since BRIDGE_TESTBED is set. Minions will be exposed on your local network"
end

$hostname_setup = <<SCRIPT
  echo "$1" > /etc/hostname
  hostname "$1"
  sed -i "s/127.0.0.1\\(.\\+\\)/127.0.0.1\\1 $1/g" /etc/hosts
SCRIPT

VAGRANTFILE_API_VERSION = "2"

class VMDefFactory
  def initialize(vagrant_config:, salt_version:, salt_development:, use_bridged_network:, bridge_interface: nil, vm_name_prefix: nil)
    @vagrant_config = vagrant_config
    @salt_version = salt_version
    @salt_development = salt_development
    @bridged_testbed = use_bridged_network
    @bridge_interface = bridge_interface
    @vm_name_prefix = vm_name_prefix
  end

  def createMaster(master_name:, memory:, private_network_ip:, forward_salt_ports: false, is_minion: false)
    config = @vagrant_config
    if @vm_name_prefix
      master_name = "#{@vm_name_prefix}-#{master_name}"
    end

    config.vm.define master_name do |master|
      master.vm.box = "ubuntu/trusty64"
      master.vm.provider "virtualbox" do |v|
        v.memory = memory
        v.cpus = 2

      end

      master.vm.provision "shell", inline: $hostname_setup, args: master_name
      master.vm.provision "shell" do |s|
        s.path = "vagrantscripts/provision_ubuntu1404_master.bash"
        s.args = [ "#{@salt_development}", master_name, "#{is_minion}", @salt_version ]
      end

      if @bridged_testbed
        master.vm.network "public_network", bridge: @bridge_interface
      end
      master.vm.network "private_network", ip: private_network_ip
      if forward_salt_ports
        master.vm.network "forwarded_port", guest: 4505, host: 4505
        master.vm.network "forwarded_port", guest: 4506, host: 4506
      end
    end
  end

  def createMinion(minion_name:, master_ip:, auto_start:, memory:, private_network_ip:)
    config = @vagrant_config
    if @vm_name_prefix
      minion_name = "#{@vm_name_prefix}-#{minion_name}"
    end

    config.vm.define minion_name, autostart: auto_start do |minion|
      minion.vm.box = "ubuntu/trusty64"
      minion.vm.provider "virtualbox" do |v|
        v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
        v.memory = memory
        v.cpus = 2
      end

      minion.vm.provision "shell", inline: $hostname_setup, args: minion_name
      minion.vm.provision "shell" do |s|
        s.path = "vagrantscripts/provision_ubuntu1404_minion.bash"
        s.args = [ "#{@salt_development}", minion_name, master_ip, @salt_version ]
      end

      if @bridged_testbed
       minion.vm.network "public_network", bridge: @bridge_interface
      end
      minion.vm.network "private_network", ip: private_network_ip
    end
  end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  factory = VMDefFactory.new(vagrant_config: config,
    salt_version: testbed_config["salt_version"],
    salt_development: testbed_config["salt_development"],
    use_bridged_network: testbed_config["use_bridged_network"],
    bridge_interface: testbed_config["bridge_interface"],
    vm_name_prefix: testbed_config["vm_name_prefix"])

  # Create the master minion definition
  factory.createMaster(master_name: "master",
    memory: testbed_config["master_mem"],
    private_network_ip: "192.168.51.2",
    forward_salt_ports: testbed_config["forward_master_ports"],
    is_minion: testbed_config["masters_are_minions"])

  # Create a second master, if necessary
  if testbed_config["multi_master"]
    factory.createMaster(master_name: "master1",
      memory: testbed_config["master_mem"],
      private_network_ip: "192.168.51.3",
      forward_salt_ports: testbed_config["forward_master_ports"],
      is_minion: testbed_config["masters_are_minions"])
  end

  # Create the bigminion defintion
  factory.createMinion(minion_name: "bigminion",
    master_ip: testbed_config["use_master_ip"],
    auto_start: false,
    memory: testbed_config["bigminion_mem"],
    private_network_ip: "192.168.51.4")

  # Create regular minions 1-5
  (1..5).each do |i|
    factory.createMinion(minion_name: "minion#{i}",
      master_ip: testbed_config["use_master_ip"],
      auto_start: (i == 1),
      memory: testbed_config["bigminion_mem"],
      private_network_ip: "192.168.51.#{4+i}")
  end
end
