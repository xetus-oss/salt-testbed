# Salt Development Mode

The testbed offers a quick way to get started if you're patching or adding features to salt itself. It only takes the following to get started:


1. Checkout the salt source you'll be working on into the `salt-src` directory in the testbed. 
2. Set the configuration variable `salt_development` to `true` either using the `testbed.yml` or the `SALT_DEVELOPMENT` environment variable.
3. Use `vagrant up`. 

The vagrant script will setup the salt development environrment according to the [recommended setup](https://docs.saltstack.com/en/latest/topics/development/hacking.html). If you aren't familiar with that setup, please go read about it!

The key points that are different about the testbed setup are:

* The virtual environment base is `/virtenv`
* All the configuration files that would normally be used in the salt testbed are used.

Once the VMs are created, the quickest way to go make sure the development mode is working is to log into the master and issue the following commands:

```
sudo su
source /virtenv/bin/activate
salt '*' test.ping
```
