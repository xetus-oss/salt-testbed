# Testbed Tools

These modest testbed tools were added to make it easier to work with salt formula's stored in different git repositories. If you're like us, you'll want to keep each salt formula separate. However, the checkout/update process can be very tedious as the number of formulas you're working with grows. The tools included with the testbed make this a little easier.

#### Syncing git formulas in bulk

Add all the formulas you need to work with as git urls to the `salt/formulas/repo.list` file (one per line), then run `./tools/update-formulas`. This will sync all entries under `salt/formulas/`. Then it's just a matter of adding the ones you're testing to your `config/salt-master-config` file.

An example for the `salt/formulas/repo.list` is:

```
git@gitlab.internal.company.com:saltstack/formula1.git
git@gitlab.internal.company.com:saltstack/formula2.git
```

#### Detecting formula changes

Use `./tools/detect-formula-changes` to figure out which formulas have been changed without having to issue a `git status` in each formula directory.

#### Updating formula changes

Use `./tools/update-formulas` to grab the most recent copy of each formula.

Note, this only automates a git pull --rebase command. You will have to manually account for merging, etc., just like with any other repo.

#### Swapping formula branches

Use `./tools/branch-formulas` to checkout new formula branches. If the branch does not already exist, it will be created. This tool can also be used to delete local branches created in error.
