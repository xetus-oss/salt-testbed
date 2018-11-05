# Using WinRepo With the Salt Testbed

While the Salt winrepo certainly fills a missing package management void for Windows systems, it is certainly challenging to work with. This documentation is intended to help use the winrepo with the salt testbed, specifically for development of winrepo package definitions.

#### The Goal

The ideal development setup (achieved via the instructions below) allows for easily and quickly iterating on local definition files to work through syntax and logic errors before pushing to the git repository for the winrepo containing the definition.

## Setup

The following steps will walk you through the initial setup of:

* local winrepo clone with definition SLS files stored on the saltmaster;
* winrepo shared to the winminion via the `primarymaster`'s Salt filesystem.

#### Important!

There are a few important points to get this working properly:

**!! CAUTION !! DO NOT RUN winrepo.update_git_repos!!** This will potentially delete and overwrite your local winrepo!

1. These instructions assume you're using Salt version at or later than 2015.8.0 and will need some slight modifications to support earlier versions. Please see the [SaltStack documentation](https://docs.saltstack.com/en/latest/topics/windows/windows-package-manager.html) for details on what modifications you might need to make.

2. These instructions assume you'll clone the winrepo you're testing (or to which you're adding a new or modifying an existing package definition) to a `salt/windows/win/repo-ng` directory from the root of this project, but you can choose a different directory; just make sure to modify the `primarymaster`'s `file_roots:base` and `winrepo_dir_ng` configurations appropriately.

#### Steps

1. Clone your winrepo into the `salt/windows/win/repo-ng` directory of this testbed;
2. Update your master configuration based on the following example:

  ```yaml
  fileserver_backend:
    - roots

  file_roots:
    base:
      #
      # This is necessary so that the saltmaster will
      # serve /vagrant/salt/windows/win/repo-ng on the 
      # Salt FS as salt://win/repo-ng, which is where 
      # the winminion's default configuration will look 
      # for it.
      #
      - /vagrant/salt/windows/

  #
  # Unless you need packages from the official Saltstack winrepos,
  # set yourself up to only use your local winrepo for easier 
  # development.
  #
  winrepo_remotes: []
  winrepo_remotes_ng: []
  
  #
  # This is the magic, and mildly dangerous -- so long as you don't
  # run `update_git_repos` your local changes won't be removed.
  #
  winrepo_dir_ng: /vagrant/salt/windows/win/repo-ng
  ```

  **Make sure to restart the salt-master service by running `systemctl restart salt-master` from the `primarymaster`**

3. From the `primarymaster`: Update the winminion's package db:

  ```bash
  salt winminion pkg.refresh_db
  ```

  If everything went successfully, you should see some successes or failures. Failures likely mean you need to fix syntax errors in your package definitions, but are a good sign since they mean the Windows minion is able to pull down your local winrepo. You're in business either way, so nice work!

## Development Workflow

#### Steps

1. Hack on your package definition within the winrepo;
2. From the `primarymaster`, run the `pkg.refresh_db` module to propogate your changes to the Windows minion and have it evaluate your definition's jinja:

  ```bash
  salt winminion pkg.refresh_db
  ```

3. If the above step had errors, try to correct them, re-running `salt winminion pkg.refresh_db` from the `primarymaster` as you go to check once you're changes are valid.
4. Once your `pkg.refresh_db` commands return success, confirm your package definition renders as expected:

  ```bash
  salt winminion pkg.get_repo_data
  ```

5. When ready, you can test out installation and removal of your package:

  ```bash
  # test out installing your package from the winrepo
  salt winminion pkg.install {{my_pkg}} {{pkg_version}}
  
  # test out uninstalling your package from the winrepo
  salt winminion pkg.remove {{my_pkg}}

  # etc...
  ```

6. When ready, commit and push your changes to your winrepo's git repository.

## Verification Workflow

Once you've pushed your changes, it's a good idea to destroy your local test bed VMs via `vagrant destroy`, re-create them, and test against your winrepo's git repository.

#### Steps

1. update your `priamrymaster`'s configuration to:
    1. add your winrepo git repository's url to the `winrepo_remotes_ng` list; and
    2. comment out the `winrepo_dir_ng` configuration to keep from overwriting your local winrepo clone;
2. restart the salt-master: `systemctl restart salt-master`;
3. have Salt clone your git repo: `salt-run winrepo.update_git_repos`
4. update the winminion's pkg db: `salt winminion pkg.refresh_db`
5. verify the packages can be managed as expected.
