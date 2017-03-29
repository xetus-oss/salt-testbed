# Overview

A [Vagrant](https://www.vagrantup.com) based testbed for developing with [Salt Stack](http://saltstack.com) and Ubuntu servers. Our goal is to be the easiest to use salt testbed out there.

The testbed is made up of the following components:

* Vagrant scripts which manage the creation/association of a salt master VM and one or more minions.
* A default salt configuration and layout which should be suitable for most Ubuntu-based environments

# Quickstart

The below commands will create two VM's, "master" and "minion1", with a consistent version of salt (currently **v2016.11**, though this is configurable).

1. `vagrant up`
2. `vagrant ssh master` 
3. `sudo salt '*' test.ping`

# Available VM's

The following vms are available locally by simply using `vagrant up <name>`.

|Name      |When Created|Description           |
|----------|------------|----------------------|
|master    |default|The salt-master            |
|minion1   |default|The first minion to work with. Suitable for most tests|
|minion2-5 |manual|Additional minions for testing|
|bigminion |manual|A minion with significant resources for heavy tests|

All systems are Ubuntu 14.04 systems, and are connected to each other through a secondary internal network provided by VirtualBox.

# Configuration Parameters

The VM's defined in by the Vagrant file can be configured in a variety of ways using either environment variables or the `testbed.yml` configuration file. The table below describes the available options:


* `salt_version`:
  * YAML key: `salt_version`
  * Environment Variable: `SALT_VERSION`
  * Default: `2016.11.2`
  * Description: The version of salt to install, this is passed to salt bootstraps install_salt.sh. Note, this is an incompatible option with `salt_development`
* `salt_development`
  * YAML key: `salt_development`
  * Environment Variable: `SALT_DEVELOPMENT`
  * Default: `false`
  * Description: Instructs the testbed to setup a development environment with, using `salt-src` as the salt installation. This option will cause `salt_version` to be ignored.
* `minion_mem`:
  * YAML key: `minion_mem`
  * Environment Variable: `MINION_MEM`
  * Default: `2048`
  * Description: The memory allocated, per minion
* `master_mem`:
  * YAML key: `master_mem`
  * Environment Variable: `MASTER_MEM`
  * Default: `512`
  * Description: The memory allocated to masters
* `bigminion_mem`:
  * YAML key: `bigminion_mem`
  * Environment Variable: `BIGMINION_MEM`
  * Default: `4096`
  * Description: The memory allocated to the special "bigminion"
* `use_master_ip`
  * YAML key: `use_master_ip`
  * Environment Variable: `USE_MASTER_IP`
  * Default: `192.168.51.2`
  * Description: The master ip to use for minions. The default is the local master ip, but this must be overriden if your master is on a different system.
* `use_bridged_network`
  * YAML key: `use_bridged_network`
  * Environment Variable: `USE_BRIDGED_NETWORK`
  * Default: false
  * Description: Tells the testbed to bind hosts to a bridged network. Useful if you're test environment spans multiple local computers.
* `bridge_interface`
  * YAML key: `bridge_interface`
  * Environment Variable: `BRIDGE_INTERFACE`
  * Default: none
  * Description: Required if "USE_BRIDGED_NETWORK" is true. Hint, use `VBoxManage list bridgedifs` 
* `vm_name_prefix`
  * YAML key: `vm_name_prefix`
  * Environment Variable: `VM_NAME_PREFIX`
  * Default: none
  * Description: Useful if you want to have all the vms identified by their host. Particularly helpful when your local test environment spans multiple computers.
* `forward_master_ports`
  * YAML key: `forward_master_ports`
  * Environment Variable: `FORWARD_MASTER_PORTS`
  * Default: false
  * Description: Forwards all the master ports so they are externally accessible. This is most useful when you're using your local system as the master for remote minions, such as those on the other side of a VPN.
* `masters_are_minions`
  * YAML key: `masters_are_minions`
  * Environment Variable: `MASTERS_ARE_MINIONS`
  * Default: false
  * Description: Have the master vm be a minion itself.

# Testbed organization

* `config/`: This directory contains configuration files that are symlinked in the various master/minion VM's. Each vagrant vm has a configuration sub directory of `config/{vagrant_vm_id}` which contains the appropriate configuration directory (master.d and/or minion.d). Any configuration files placed in those directories will be loaded so that the configuration can be broken into several files.
  
* `templates/`: This directory contains templates for initializing new salt testbed setups. The files are copied into their respective directories when `vagrant up` is ran and a new environment is detected.

* `salt`: This is the base directory for the salt environment, you can think of it as `/srv/` in a production environment. The salt directory is divided into several sub-directories to keep things organized as the environment increases in complexity.

* `salt-src` **(optional)**: If using the `salt_development` feature, then place the salt source in this directory. See [Salt Development Mode](docs/salt-development-mode.md) for more information.

# Documentation

1. [Common Tasks](docs/common-tasks.md)
3. [FAQs](docs/faqs.md)
6. [Salt Development Mode](docs/salt-development-mode.md)