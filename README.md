# Ansible playbook to configure your accounts

[toc]

## Requirements

* _Ansible_ >= 2.4
* `AdministratorAcces` on the _Organization_ account
* Environment variables are set and exported:
  * `AWS_ACCESS_KEY_ID`
  * `AWS_SECRET_ACCESS_KEY`
  * `AWS_REGION`
* A configuration file that describes your complete account setup

## PlayBooks in this repo

### `aws-account-setup`

This is the main playbook, and it includes all other playbooks

### `aws-account-basic-setup.yml`

### `aws-account-security-setup.yml`

## What the playbook does

## The configuration file

The configuration file looks like this:

```$xslt
### The organization account configured the sub-accounts, and
### has the necessary AssumeRoles permissions to perform all
### required IAM actions on the new accounts. These credentials
### are very valuable, and should only be active when running
### this playbook!!!
organization:
  account_id: "123456789012"
  name: acme

environments:
  - dev
  - stg
  - prd
  - sandbox

entities:
  - acme
  - acme_emea

bastion_account:
  name: acme.bastion
  account_id: "012345678901"
  console_url: "https://acme-bastion.signin.aws.amazon.com/console"

subaccounts:
  - name: acme.sandbox
    account_id: "234567890123"
    environment: sandbox
  - name: acme.salesapp
    account_id: "345678901234"
    environment: prd

### Groups will be created on the bastion account only.
### Group names are <name>-<accountid>, where <name> is the groupname
### defined in this list, and <account-id> is the account id of the
### subaccounts listed in the subaccounts list.
### Membership to a group implies the permissions to assume the role
### (i.e read) on the account with that account id
aws_groups:
  - name: AssumeRead
    role: read
  - name: AssumePower
    role: power
  - name: AssumeAdmin
    role: admin

### Roles are created on every subaccount, they are required to have users
### assume a role
aws_roles:
  - name: read
    managed_policies:
      - ReadOnlyAccess
  - name: admin
    managed_policies:
      - AdministratorAccess
  - name: power
    managed_policies:
      - PowerUserAccess

### Users
#default_groups: "{{ ['ManageYourOwnUser'] + ( subaccounts | map(attribute='name') | map('regex_replace', '^', 'AssumeRead-') | list ) }}"
#aws_users:
#  - name: rtytgat
#    groups: "{{ subaccounts | map(attribute='name') | map('regex_replace', '^', 'AssumeAdmin-') | list }}"
default_groups:
  - ManageYourOwnUser

aws_users:
  - name: "john.doe@acme.com"
    groups:
      - Admin
  - name: "bill.smith@acme.com"
    groups:
      - AssumeRead-acme.salesapp-prd

```

## Available `tags` to limit the scope of the execution

### `html`

Create the `.html` file with all available cross-account links

### `bastion_grouppolicy`

Create the groups and group policies on the _Bastion_ account

### `bastion`

Perform everyting on the _Bastion_ account. This is basically the
complete playbook, but without:

* `html`
* Creation of the roles on the subaccounts

### `passwordpolicy`

Set the IAM password policy on all subaccounts.

### `create_users` 

Only create users and assign groups to the users. Since users only
exist on the _Bastion_ account, this is the only account involved.

### `basic`

Do not run the `monitoring` and `security` playbooks.

### `security`

Only run the `security` tasks.

### `monitoring`

Only run the `monitoring` tasks.

### `subaccounts`

Only run the playbooks that change stuff on the subaccounts.

If the variable `subaccount_limit` is set, the subaccount actions are
only performed for that account.

```
--extra-vars subaccount_limit=ixor.acertabudgettool-dev
```

### `security_guardduty`

Only run the `guardduty` tasks.


## Available `--extra-vars`

### `config-file`

The configuration file to use. The configuration file contains the description
of your account structure, defines the _Organization_ account, the account to use
as the _Bastion_ account, all subaccounts, users and group membership for the users.

### `subaccount_limit`

Limit the subaccount actions to the specified subaccount

## Examples

### Create the HTML page with the x-account links

```
ansible-playbook aws-account-setup.yml --extra-vars=config_file=../aws-account-config-ixor/aws-account-config.yml --tags=html
```

### Run the playbook to create 1 account

```
### Create groups etc. on the bastion account
ansible-playbook aws-account-setup.yml \
    --extra-vars="config_file=../aws-account-config-ixor/aws-account-config.yml" \
    --tags=bastion
### Setup the subaccount, run once for every subaccount
ansible-playbook aws-account-setup.yml \
    --extra-vars="config_file=../aws-account-config-ixor/aws-account-config.yml subaccount_limit=<accountname>" \
    --tags=subaccounts
### Add access to tooling buckets to new account
ansible-playbook aws-account-setup.yml \
    --extra-vars="config_file=../aws-account-config-ixor/aws-account-config.yml" \
    --tags=tooling
### Setup security stuff
ansible-playbook aws-account-setup.yml \
    --extra-vars="config_file=../aws-account-config-ixor/aws-account-config.yml" \
    --tags=security
### Setup monitoring stuff
ansible-playbook aws-account-setup.yml \
    --extra-vars="config_file=../aws-account-config-ixor/aws-account-config.yml" \
    --tags=monitoring
```

How long do these playbooks take to run?

* `bastion` part for 44 accounts: 20 minutes
* The account setup for 1 account:  about 90 seconds
* The `monitoring` tasks: about 5 minutes (should not be limited to 1 account)
* The `security` related actions: about 10 minutes (should not be limited to 1 account)

### Only create and update users and user permissions

```
TODO ansible-playbook aws-account-setup.yml --extra-vars=config_file=../aws-account-config-ixor/aws-account-config.yml --tags=create_users
```
