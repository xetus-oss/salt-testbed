# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

#
# Configure the various parameters available to customize your testbed
#
mem_per_system = 2048
use_bridged_testbed = false
bridge_interface = nil
multi_master = false
masters_are_minions = false
forward_master_ports = false

#
# see the salt-bootstrap README for details:
# https://github.com/saltstack/salt-bootstrap
#
salt_version = "git v2015.8.0"

yaml_config_file = File.dirname(__FILE__) + "/testbed.yml"
yaml_config = nil
if File.file?(yaml_config_file)
  yaml_config = YAML.load_file(yaml_config_file)
end

if yaml_config
  bridge_interface = yaml_config.has_key?('bridge_interface') ? yaml_config['bridge_interface'] : bridge_interface
  mem_per_system = yaml_config.has_key?('minion_mem') ? yaml_config['minion_mem'] : mem_per_system
  use_bridged_testbed = yaml_config.has_key?('use_bridged_testbed') ? yaml_config['use_bridged_testbed'] : use_bridged_testbed
  multi_master = yaml_config.has_key?('multi_master') ? yaml_config['multi_master'] : multi_master
  masters_are_minions = yaml_config.has_key?('masters_are_minions') ? yaml_config['masters_are_minions'] : masters_are_minions
  salt_version = yaml_config.has_key?('salt_version') ? yaml_config['salt_version'] : salt_version
  forward_master_ports = yaml_config.has_key?('forward_master_ports') ? yaml_config['forward_master_ports'] : forward_master_ports
end


mem_per_system = ENV['MINION_MEM'] ? ENV['MINION_MEM'] : mem_per_system
use_bridged_testbed = ENV['BRIDGE_TESTBED'] ? true : use_bridged_testbed
bridge_interface = ENV['BRIDGE_INTERFACE'] ? ENV['BRIDGE_INTERFACE'] : bridge_interface
multi_master = ENV['MULTI_MASTER'] ? true : multi_master
masters_are_minions = ENV['MASTERS_ARE_MINIONS'] ? true : masters_are_minions
salt_version = ENV['SALT_VERSION'] ? ENV['SALT_VERSION'] : salt_version
forward_master_ports = ENV['FORWARD_MASTER_PORTS'] ? ENV['FORWARD_MASTER_PORTS'] : forward_master_ports

if use_bridged_testbed and ARGV[0] == "up"
  puts "!! Using a bridged testbed since BRIDGE_TESTBED is set. IPs for the minions will be retrieved by DHCP"
end

$master_setup = <<SCRIPT

  # https://github.com/saltstack/salt-bootstrap
  curl -L https://bootstrap.saltstack.com -o install_salt.sh
  sudo sh install_salt.sh -M -U -P #{salt_version}

  service salt-master stop
  mv /etc/salt/master /etc/salt/master.orig
  
  # Allow the master config to be preserved between vm re-creations
  if [ ! -e  /vagrant/config/salt-master-config ]
  then
    mkdir -p /vagrant/config/
    cp /vagrant/templates/salt-master-config /vagrant/config/salt-master-config
  fi
  ln -s /vagrant/config/salt-master-config /etc/salt/master
  
  # Copy the template files if they do not already exist
  if [ ! -e /vagrant/salt/states/top.sls ]
  then
    cp /vagrant/templates/state_top.sls /vagrant/salt/states/top.sls
  fi
  if [ ! -e /vagrant/salt/states/example-rsyslog.sls ]
  then
    cp /vagrant/templates/state_example-rsyslog.sls /vagrant/salt/states/example-rsyslog.sls
  fi
  if [ ! -e /vagrant/salt/pillar/top.sls ]
  then
    cp /vagrant/templates/pillar_top.sls /vagrant/salt/pillar/top.sls
  fi
  if [ ! -e /vagrant/salt/pillar/defaults.sls ]
  then
    cp /vagrant/templates/pillar_defaults.sls /vagrant/salt/pillar/defaults.sls
  fi
  if [ ! -e /vagrant/salt/pillar/common.sls ]
  then
    cp /vagrant/templates/pillar_common.sls /vagrant/salt/pillar/common.sls
  fi
  
  # Install the salt-minion service if desired and expose a stateful
  # configuration file
  if [[ #{masters_are_minions ? "true" : "false"} -eq "true" ]]; then
    sed -i "s/#master:.*/master: localhost/g" /etc/salt/minion
    [[ ! -e /vagrant/config/$1.minion.conf ]] && \
      echo "# Enter minion configuration overrides for $1 below" > /vagrant/config/$1.minion.conf
    ln -s /vagrant/config/$1.minion.conf /etc/salt/minion.d/$1.minion.conf
    service salt-minion restart
  fi

  [ ! -e /vagrant/salt/states/top.sls ] &&\
    cp /vagrant/templates/state_tops.sls /vagrant/salt/states/top.sls
  [ ! -e /vagrant/salt/pillar/defaults.sls ] &&\
    cp /vagrant/templates/pillar_defaults.sls /vagrant/salt/pillar/defaults.sls
  [ ! -e /vagrant/salt/pillar/common.sls ] &&\
    cp /vagrant/templates/pillar_common.sls /vagrant/salt/pillar/common.sls
  [ ! -e /vagrant/salt/pillar/top.sls ] &&\
    cp /vagrant/templates/pillar_top.sls /vagrant/salt/pillar/top.sls
  
  service salt-master start
SCRIPT

$minion_setup = <<SCRIPT
  # https://github.com/saltstack/salt-bootstrap
  curl -L https://bootstrap.saltstack.com -o install_salt.sh
  sudo sh install_salt.sh -P -U #{salt_version}

  sed -i "s/#master:.*/master: 192.168.51.2/g" /etc/salt/minion
  if [ ! -e /vagrant/config/$1/ ]
  then
    mkdir -p /vagrant/config
  fi

  # Expose a stateful configuration file
  [[ ! -e /vagrant/config/$1.conf ]] && \
    echo "# Enter minion configuration overrides for $1 below" > /vagrant/config/$1.conf
  ln -s /vagrant/config/$1.conf /etc/salt/minion.d/$1.conf
  service salt-minion restart
SCRIPT

$hostname_setup = <<SCRIPT
  echo "$1" > /etc/hostname
  hostname "$1"
  sed -i "s/127.0.0.1\\(.\\+\\)/127.0.0.1\\1 $1/g" /etc/hosts
SCRIPT

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/trusty64"
    master.vm.provider "virtualbox" do |v|
      v.memory = 512
      v.cpus = 2
    end
    
    master.vm.provision "shell", inline: $hostname_setup, args: "master"
    master.vm.provision "shell", inline: $master_setup, args: "master"
    if use_bridged_testbed
      master.vm.network "public_network", bridge: bridge_interface
    end
    master.vm.network "private_network", ip: "192.168.51.2"
    if forward_master_ports
      master.vm.network "forwarded_port", guest: 4505, host: 4505
      master.vm.network "forwarded_port", guest: 4506, host: 4506
    end
  end
  
  config.vm.define "bigminion", autostart: false do |bigminion|
    bigminion.vm.box = "ubuntu/trusty64"
    bigminion.vm.provider "virtualbox" do |v|
      v.memory = 4096
      v.cpus = 2
    end

    bigminion.vm.provision "shell", inline: $hostname_setup, args: "bigminion"
    bigminion.vm.provision "shell", inline: $minion_setup, args: "bigminion"
    if use_bridged_testbed
      bigminion.vm.network "public_network", bridge: bridge_interface
    end
    bigminion.vm.network "private_network", ip: "192.168.51.3"
  end

  (1..5).each do |i|
    auto_start_minion = (i == 1)
    config.vm.define "minion#{i}", autostart: auto_start_minion do |minion|
      minion.vm.box = "ubuntu/trusty64"
      minion.vm.provider "virtualbox" do |v|
        v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
        v.memory = mem_per_system
        v.cpus = 2
      end

      minion.vm.provision "shell", inline: $hostname_setup, args: "minion#{i}"
      minion.vm.provision "shell", inline: $minion_setup, args: "minion#{i}"
      if use_bridged_testbed
        minion.vm.network "public_network", bridge: bridge_interface
      end
      minion.vm.network "private_network", ip: "192.168.51.#{3+i}"
    end
  end

  if multi_master
    config.vm.define "master1" do |master|
      master.vm.box = "ubuntu/trusty64"
      master.vm.provider "virtualbox" do |v|
        v.memory = 512
        v.cpus = 2
      end
      
      master.vm.provision "shell", inline: $hostname_setup, args: "master1"
      master.vm.provision "shell", inline: $master_setup, args: "master1"
      if use_bridged_testbed
        master.vm.network "public_network", bridge: bridge_interface
      end
      master.vm.network "private_network", ip: "192.168.51.9"
    end
  end
end
