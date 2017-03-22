# Common tasks

## Working on formulas

Place the formula under `salt/formulas`, then add the directory to the `file_roots` directive in `config/master/master`. For example, if adding 'myservice-formula' the config/master/master would contain:

```
file_roots:
  base:
     # Needed for a windows minion bug 
    - /vagrant/salt/proxy-for-bug-15926/
    - /vagrant/salt/states
    - /vagrant/salt/formulas/my-service-formula
```

And the new formula's directory would look like:

```
salt/formulas/myservice-formula/
  myservice/
    init.sls
  README.md
  pillar.example
```


## Working with multiple git repositories

If you're like us, and have lots of formulas (30+), managing them can be pretty difficult. We recommend using [gr](https://github.com/mixu/gr) for your formula management.

