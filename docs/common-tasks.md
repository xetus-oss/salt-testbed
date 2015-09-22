# Common tasks

##### Creating a new formula

Place the new formula under `salt/formulas`, then add the directory to the `file_roots` directive in `config/salt-master-config`. For example, if adding 'myservice-formula' the config/salt-master-config would contain:

```
file_roots:
  base:
     # Needed for a windows minion bug 
    - /vagrant/salt/proxy-for-bug-15926/
    - /vagrant/salt/states
    - /vagrant/salt/formulas/myservice-formula
```

And the new formula's directory would look like:

```
salt/formulas/myservice-formula/
  myservice/
    init.sls
  README.md
  pillar.example
```

Once these changes are made, be sure to restart the salt-master service.

##### Working with an existing formula, stored in a git repository

To work with an existing formula that is stored in a git repository, simply add the git repository to `salt/formulas/repo.list` and run `./tools/update-formulas`. See the [Tools Documentation](../tools/README.md) for more information.

#### Editing pillar data

Pillar files are stored in the `salt/pillar` directory by default. Start with a `top.sls` file and add configurations as necessary. Note, it's  a common convention to use the `salt/pillar_files` directory for pillar data that is too large to reasonably be put in YAML.


#### Editing the salt-master's configuration

Just edit the `config/salt-master-config` file and restart the salt-master service.