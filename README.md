# Overview

A [Vagrant](https://www.vagrantup.com) based testbed for salt formulas, specifically when these formulas require complex setups involving multiple systems. The testbed works by creating VM's that are set up with salt, connected to a common salt-master, and providing a somewhat standard salt-master layout. By default, the `Vagrantfile` creates only 2 VM's, a master and a minion, but many others are available.

# Quickstart

The below commands will create create two VM's, "master" and "minion1", set up with a consistent version of salt (currently **v2015.5.0**, though this is configurable). 

1. `vagrant up`
2. `vagrant ssh master` 
3. `sudo salt '*' state.highstate`

### Available Local Systems

The following systems are available locally by simply using `vagrant up <name>`. All systems are Ubuntu 14.04 systems.

|Name      |When Created|Description      |
|----------|-------|-----------------|
|master    |default|The salt-master|
|minion1   |default|The first minion to work with. Suitable for most tests |
|minion2-5 |manual|Additional minions for testing|
|bigminion |manual|A minion with significant resources for heavy tests|

# Testbed organization

* `config/`: This directory contains configuration files that are symlinked into the various master/minion VM's. The salt master's `/etc/salt/master` configuration file is symlinked to `config/salt-master-config`. Also, each local minion gets an override config file named `config/<minionid>.minon.conf` which is symlinked to `/etc/salt/minion.d/<minionid>.minon.conf`.
  
* `templates/`: This directory contains templates for initializing new salt testbed setups. The files are copied into their respective directories when `vagrant up` is ran and a new environment is detected.

* `salt`: This is the base directory for the salt environment, you can think of it as `/srv/` in a production environment.

* `tools`: Included here are the various tools to make working with re-usable salt formulas a little easier. It's primarily focused around using git to work with formulas stored in their own project.

# Common tasks

##### Adding a formula directory to the salt-master's `file_roots`

Edit the master's configuration by editing `config/salt-master-config`.

#### Editing pillar data

Pillar files, by default, are stored in the `salt/pillar` directory. Start with a `top.sls` file and add configurations as necessary. Note, it's  a common convention to use the `salt/pillar_files` directory for pillar data that is too large to reasonably be put in YAML.

# Working with salt formulas stored in individual git repositories

If you're like us, you'll want to keep each salt formula in a separate git repository. However, the checkout/update process can be very tedious since formulas need to be used together in testing/development. The tools included with the testbed make this a little easier.

#### Syncing git formulas in bulk

Add all the formulas you need to work with as git urls to the `salt/formulas/repo.list` file (one per line), then run `./tools/update-formulas`. This will sync all entries under `salt/formulas/`. Then it's just a matter of adding the ones you're testing to your `config/salt-master-config` file.

An example for the `salt/formulas/repo.list` is:

```
git@gitlab.internal.company.com:saltstack/formula1.git
git@gitlab.internal.company.com:saltstack/formula2.git
```

#### Detecting formula changes

Use `./tools/detect-formula-changes` to figure out which formulas have been changed. This is important when testing how different formulas interact.

#### Updating formula changes

Use `./tools/update-formulas` to grab the most recent copy of each formula. Note, this only automates a git pull --rebase command. You will have to manually account for merging, etc., just like with any other repo.

#### Swapping formula branches

Use `./tools/branch-formulas` to checkout new formula branches. If the branch does not already exist, it will be created. This tool can also be used to delete local branches created in error.

## Advanced VM Configuration

#### Adjusting the minion VM configuration

The following environment variables or `testbed.yml` values can be used to adjust the minions created in the testbed. 

(testbed.yml value|Environment variable)

* __salt_version|SALT_VERSION__: The version of salt to install
* __mem_per_system|MINION_MEM__: The memory per minion, default is 2048
* __use_bridged_testbed|BRIDGE_TESTBED__: Whether or not to use a bridged interface. Default's to `false`;
* __bridge_interface|BRIDGE_INTERFACE__: The bridged interface to use, only relevant when use_bridged_testbed is true

After either setting the environment variables, or configuring `testbed.yml`, recreate the VM's to get the new settings.

#### Using Remote Systems

Sometimes the environment you're testing needs more resources than your local system can provide, or perhaps you just don't want your local system bogged down with a bunch of heavy VMs. In this case, there you can use the `remote-Vagrantfile` and use another system with Vagrant installed.

Using remote minions brings a few challenges to be aware of.

##### Setup all necessary network access on the remote host

If your VM's need to communicate with systems over a VPN, you'll need to make sure the remote system has that VPN configured and connected.

This comes up in cases when you're testing a service configuration that requires access to other services that it's not convenient to run locally (e.g. LDAP, gitlab, etc), and those services are only available on protected networks. You probably don't want to setup _all_ of the various services locally, it's often easier to to perform read-only operations against already-running instances than create local copies for each of them.

##### Setup your local testbed to run in bridged mode

You're definitely going to want to have your salt minions talk to the salt-master! The easiest way to make the salt-master available over the network is to run it with bridged networking (`use_bridged_testbed`). A local `testbed.yml` file can be used to preserve the setting.

##### Remote testbed minion quickstart

1. Setup your local vagrant environment in bridged mode by creating a `testbed.yml` file in the project root with `use_bridged_testbed: true`. Bring up your local system and note the IP address of the salt-master.
2. Copy the `remote-Vagrantfile`  to some target system, renaming it to the standard `Vagrantfile`
3. Setup a `testbed.yml` in the same directory as the `Vagrantfile` on the remote system with at least the `master_ip` value (see below for complete options)
4. Use the standard `vagrant up` to startup your remote minions!

##### Configuration options 

* __mem_per_system__: The memory per minion, default is 2048
* __num_systems__: The number of minions, default is 2
* __name_prefix__: Minions are mamed with ${name_prefix}-minion${N}. The default is the hostname, but you really want to set this value to something nice and short to make your life easier.
* __bridge_interface__: Define the bridge interface to use when starting minions. You *really* want to set this. Having to select the bridged interface every time is a pain.

# FAQs / Hints

##### Why is the CPU usage so high on the salt mater?

Salt masters take a long time to boot up, just how it is. They should startup in about 10-20 seconds, then the CPU will die down.

##### My minion stopped responding to the master after destroyed/re-created it

Delete the salt key and re-restart he minion's salt daemon.

1. On the master: ```salt-key -d minionId ```
2. On the minion:  ```service salt-minion restart```

##### Warning: These minions are not as fast as boot2docker

The boot2docker vm is well optimized to be as fast as possible, these mininon vm's are designed to allow for a reasonable density so multiple systems can be emulated. You may need more resources than the default `minion` provides, so use `big
