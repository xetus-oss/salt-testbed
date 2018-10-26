__A small, reasonably configurable, vagrant-based testbed for saltstack + Ubuntu.__

---

* [Testbed Overview](#testbed-overview)
* [Quick Start](#quick-start)
* [Configuration](#configuration)
* About
	* [VM Private Network Addresses](#vm-private-network-addresses)
	* [Externalized Salt Configuration](#externalized-salt-configuration)
	* [Scenario Testing Hints](#scenario-testing-hints)
	* [Saltstack Development](#saltstack-development)
* [FAQ](#faq)

---

# Testbed Overview

* Consists of 4 VMs, `primarymaster`, `secondarymaster`, `minion1`, and `minion2`. Only `primarymaster` and `minion1` are started by default.
* Allows for yaml-based configuration of practical provisioning parameters on a per VM basis (salt version, cpus, memory amount, etc) through a local `testbed.yaml` file. See [testbed-defaults.yaml](testbed-defaults.yaml) for more information.
* Connects all the VMs to a common private network with consistent static IP addresses for each VM.
* Includes provisioning scripts that externalize the salt configuration (`/etc/salt/`) to `host-data/{system_name}/etc-salt`. 
* Provides scripts to make it easy to run saltstack from locally built source code (useful for salt hacking).

# Quick Start

To quickly get a master and mininon speaking with each other

(1) Create the default machines

```bash
vagrant up
```

(2) Replace the `etc-salt/minion` file in the `host-data` folder for each host with the following line 

```yaml
master: 192.168.50.21
```

(3) On each system, issue the following command

```bash
vagrant ssh {system_name}
sudo systemctl restart salt-minion
```

(4) Prove that all systems are connected

```bash
vagrant ssh primarymaster
# note: you may or may not need to accept all keys
sudo salt-key -A
sudo salt '*' test.ping
```

# Configuration

The [testbed-defaults.yaml](testbed-defaults.yaml) describes the various configuration parameters, including the VM resources and the saltstack version to install. The values below the `vm_defaults` key are applied to each entry under the `vms` key, unless specified.

The default values can be overwritten by creating a `testbed.yaml` file in the root directory and defining alternate values.

# About

### VM Private Network Addresses

| Host            | Private IP    |
|-----------------|---------------|
| primarymaster   | 192.168.50.21 |
| secondarymaster | 192.168.50.22 |
| minion1         | 192.168.50.23 |
| minion2         | 192.168.50.24 |

### Externalized Salt Configuration

The data associated with each host is persisted outside of the individual VMs to make testing easier. However, this also means that you have to remember to update configuraton data between test scenarios, even if you destory the VMs.

### Scenario Testing Hints

The recommended usage for this testbed is to run specific scenario tests that can be easily re-created. Below is a suggsted directory structure:

```
	_vagrantsupport/
	docs/
	host-data/
	host-scripts/
	salt/ (** Clone formulas, modules, etc, under this directory)
	srcs/ (** Clone source code, typically salt, under this directory)
	testbed-scenarios/ (** maintain test scenarios, under version control, in this directory) 
```


### Saltstack Development

Whenever we do major upgrades of saltstack, we find we that need to contribute fixes or enhancements before we can move to the next version. This can be very time consuming and we have a series of scripts to make it less painful to run a development version of saltstack.

The easiest way to get a development version of saltstack up and running in the testbed is to use the `host-scripts/ubuntu_development_setup.bash` script. As the name suggests, it's only intended to work on Ubuntu. 

From within a VM, call the script with a salt source directory and it will handle setting up a virtual environment with that development version installed for you. For example:

```
/vagant/host-scripts/ubuntu_development_setup.bash /vagrant/srcs/salt/
```

 After that, you can manage starting and stopping the development version of salt using the handy `host-scripts/salt_dev_ctl.bash` script.


# FAQ

### Why not just use kitchen-salt for all your integration testing?

Kitchen-salt is great! But there are lots of situations where a small configurable testbed is more convenient. A few examples:

1. Developing against the saltstack source.
2. Testing of complex scenarios, especially when more than 1 host is involved, like failover in a multi-master environment or orchestration scripts.
3. Preparing infrastructure changes to your version of salt and/or linux distrobution.
