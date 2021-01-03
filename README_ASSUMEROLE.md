# Create and save AWS STS credentials for all accounts in the organization

## How to run

```bash
ansible-playbook aws-account-setup.yml \
    --extra-vars=config_file=../aws-account-config-ixor/aws-account-config.yml \
    --tags=assumerole \
    --skip-tags=never
```

## The `~/.aws-account-config.yml` local config file

The playbook will create files on the workstation where the playbook is run. To offer the freedom of
choice to the user, the file locations can be set in a personal configuration file
`~/.aws-account-config.yml`.

These properties can be set in that file:

| Name                     | Description                                                                      | Required? | Default                                    | Scope (tags) |
|--------------------------|----------------------------------------------------------------------------------|-----------|--------------------------------------------|--------------|
| `accountconfig_base_dir` | The base directory where your aws-cfn-gen account configuration repositories are | yes       | -                                          | `assumerole` |
| `sts_cache_dir`          | The directory where the temporary STS account credentials are stored             | no        | `{{ account_config_base_dir }}/.sts_cache` | `assumerole` |
| `sts_duration_seconds`   | Determines how long assumed role credentials are valid                           | no        | `3600`                                     | `assumerole` |

# What is does

* Assumes the role defined by the property `sts_role` in the organization configuration file (defaults to
  `OrganizationAccountAccessRole`)
* Stores the environment variables for that connection in a file in `{{ sts_cache_dir }}`
  (property in `~/.aws-account-config.yml`)
* Creates scripts to run the `aws-cfn-gen` `dockerwrapper` command for every account in the directory
  `{{ accountconfig_base_dir }}/scripts`
  
Such a script looks like this:

```bash
#! /bin/bash

source /Users/rik/.assumerole.d/sts_cache/ixor.doccleqa-admin

cd /Users/rik/projects/AWSAccountConfigsIxor/aws-ixor.doccle-qa-config

export ANSIBLE_TAGS
export ANSIBLE_SKIPTAGS

./dockerwrapper
```