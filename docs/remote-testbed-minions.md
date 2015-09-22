# Using testbed remote systems

Sometimes the environment you're testing needs more resources than your local system can provide, or perhaps you just don't want your local system bogged down with a bunch of heavy VMs. In this case, there you can use the `remote-Vagrantfile` and use another system with Vagrant installed.


# Quick start

1. Setup your local vagrant environment in bridged mode by creating a `testbed.yml` file in the project root with `use_bridged_testbed: true`. Bring up your local system and note the IP address of the salt-master.
2. Copy the `remote-Vagrantfile`  to some target system, renaming it to the standard `Vagrantfile`
3. Setup a `testbed.yml` in the same directory as the `Vagrantfile` on the remote system with at least the `master_ip` value (see below for complete options)
4. Use the standard `vagrant up` to startup your remote minions!

### Remote VM configuration options 

* __mem_per_system__: The memory per minion, default is 2048
* __num_systems__: The number of minions, default is 2
* __name_prefix__: Minions are mamed with ${name_prefix}-minion${N}. The default is the hostname, but you really want to set this value to something nice and short to make your life easier.
* __bridge_interface__: Define the bridge interface to use when starting minions. You *really* want to set this. Having to select the bridged interface every time is a pain.

## Gotchas

##### Setup all necessary network access on the remote host

If your local VM's need to communicate with systems over a VPN, you'll need to make sure the remote system has that VPN configured and connected.

This seems obvious, but it's a common point of confusion. It comes up in cases when you're testing a service configuration that requires access to other services where it's not convenient to run them locally (e.g. Central Auth, gitlab, etc). If the service you're testing does read-only operations against these other services, it's often easier to use the already-running instances and these are require VPN access.

