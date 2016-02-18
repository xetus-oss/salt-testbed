# Overview

A [Vagrant](https://www.vagrantup.com) based testbed for developing with [SaltStack](http://saltstack.com). The goal is to be the easiest to use testbed out there. Useful when formulas, modules, or other code requires multiple systems and services.

The testbed is made up of the following components:

* Vagrant scripts which manage the creation/association of a salt-master VM and one or more minions
* A default salt configuration and layout which should be suitable for almost all environments
* A simple set of tools for working with salt formulas stored in separate git repositories
* Tools for setting up Vagrant-managed minions on a remote system, useful when you have more than 1 computer available locally

# Quickstart

The below commands will create two VM's, "master" and "minion1", with a consistent version of salt (currently **v2015.8.0**, though this is configurable).

1. `vagrant up`
2. `vagrant ssh master` 
3. `sudo salt '*' state.highstate`

# Available VM's

The following systems are available locally by simply using `vagrant up <name>`.

|Name      |When Created|Description      |
|----------|-------|-----------------|
|master    |default|The salt-master|
|minion1   |default|The first minion to work with. Suitable for most tests|
|minion2-5 |manual|Additional minions for testing|
|bigminion |manual|A minion with significant resources for heavy tests|

All systems are Ubuntu 14.04 systems, and are connected to each other through a secondary internal network provided by VirtualBox.

# Testbed organization

* `config/`: This directory contains configuration files that are symlinked in the various master/minion VM's. The salt master's `/etc/salt/master` configuration file is symlinked to `config/salt-master-config` and each local minion gets an override config file named `config/<minionid>.minon.conf` which is symlinked to `/etc/salt/minion.d/<minionid>.minon.conf`.
  
* `templates/`: This directory contains templates for initializing new salt testbed setups. The files are copied into their respective directories when `vagrant up` is ran and a new environment is detected.

* `salt`: This is the base directory for the salt environment, you can think of it as `/srv/` in a production environment. The salt directory is divided into several sub-directories to keep things organized as the environment increases in complexity.

* `tools`: Included here are the various tools to make working with re-usable salt formulas a little easier. It's primarily focused around using git to work with formulas stored in their own project.

* `salt-src` **(optional)**: If using the `salt_development` feature, then checkout the salt source to this directory. See [Salt Development Mode](docs/salt-development-mode.md) for more information.

# Documentation

1. [Common Tasks](docs/common-tasks.md)
2. [Testbed Tools](tools/README.md)
3. [FAQs](docs/faqs.md)
4. [Optional VM Configuration](docs/vm-configuration.md) 
5. [Remote Vagrant Minions](docs/remote-testbed-minions.md)
6. [Salt Development Mode](docs/salt-development-mode.md)