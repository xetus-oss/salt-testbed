# VM Configuration

The VM's produced by the Vagrant file can be configured in a variety of ways using either environment variables or a configuration file, `testbed.yml`. The table below describes the available options:


|YAML key            |Environment Variable | Description|
|------------------- |---------------------|------------|
|salt_version        |SALT_VERSION         |The version of salt to install|
|mem_per_system      |MINION_MEM           |The memory per minion, default is 2048|
|use_bridged_testbed |BRIDGE_TESTBED       |Whether or not to use a bridged interface. Default's to `false`|
|bridge_interface    |BRIDGE_INTERFACE     |The bridged interface to use, only relevant when use_bridged_testbed is true|
|forward_master_ports|FORWARD_MASTER_PORTS |Forward ports 4505 and 4506 from the master VM on the host|


Below is an example testbed.yml

```
salt_version: v2015.5.6
use_bridged_testbed: True
```

After either setting the environment variables, or configuring `testbed.yml`, recreate the VM's to get the new settings.
