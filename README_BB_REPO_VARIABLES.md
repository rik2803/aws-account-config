# Update all ServiceAccount related repository variables

## Pre-requisites

* `admin` access on the Bastion AWS account `ixor.bastion`
* Run playbook with envvar `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` on Mac to avoid
  following error:

```
TASK [Get client_id for BB authentication from AWS SSM] ***********************************************************************************************************************************************************************************
objc[91589]: +[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called.
objc[91589]: +[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug.
ERROR! A worker was found in a dead state
```

## Tags and extra-vars

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
ansible-playbook aws-account-setup.yml \
    --extra-vars=config_file=../aws-account-config-ixor/aws-account-config.yml \
    --extra-vars=limit_bb_repo=tcc.backend.ws.wsdl \
    --tags=bb
```

## How it works?

* Retrieve the SSM Secrets with the `bb_client_id` and `bb_client_secret` for OAuth2
  authentication with BB from the organization's bastion account. See
  [here](https://support.atlassian.com/bitbucket-cloud/docs/use-oauth-on-bitbucket-cloud/)
  for instructions to create the OAuth consumer.
* The name of the SSM parameters is expected to be:
  * `bb_client_id`
  * `bb_client_secret`
* The config repository for the managed AWS organization should have a file named
  `sa_bb_config.yml` in de `BitbucketRepoConfigs` directory. This file looks like this:

```yaml
tooling_account:
  account_id: "123456789012"
aws_default_region: "eu-central-1"
repos:
  - name: "repo1"
    service_account_list:
      - name: "ACCOUNT_A"
        state: "present"
      - name: "ACCOUNT_B"
        state: "present"
    custom_vars:
      - name: "MY_VAR"
        value: "My Value"
        secured: "yes"
      - name: "MY_OTHER_VAR"
        value: "My other value"
  - name: "repo2"
    service_account_list:
      - name: "ACCOUNT_A"
        state: present
        role_to_assume: "a_not_default_role"
      - name: "ACCOUNT_B"
        state: absent
      - name: "ACCOUNT_C"
        state: "present"
```
  
* Retrieve the `<ACCOUNT>_ACCESS_KEY_ID`, `<ACCOUNT>_SECRET_ACCESS_KEY` and
  `<ACCOUNT>_ACCOUNT_ID` from SSM parameter store, and use the values to
  populate the VV pipeline variable
* When cloning `bb-aws-utils` and sourcing `lib.bash`, AWS credentials and config
  files will be created. The first account in the `service_account_list` list will
  also be the default AWS profile. To use any of the other profiles, set and export
  `AWS_DEFAULT_PROFILE` in your pipeline step.

## The configuration file

| Property                | Description                                                                                     |
|-------------------------|-------------------------------------------------------------------------------------------------|  
| `tooling-account`       | The AWS account ID where _global_ artifacts are stored                                          |
| `aws_default_region`    | The default region for the AWS profiles                                                         |
| `service_account_list`  | List of dicts for the accounts for which to create BB pipeline variables                        |
|  * `<n>.name`           | The name of the account, this will be used to retrieve the secrets from the SSM Parameter store |
|  * `<n>.role_to_assume` | The role to assume on the account, defaults to `cicd`                                           |
|  * `<n>.state`          | `present` (default) or `absent`, create or remove the BB pipeline variables for this account    |
|  `custom_vars`          | List of `name`/`value` dicts to create other BB pipeline variables                              |
|  * `<n>.name`           | The name of the variable                                                                        |
|  * `<n>.value`          | The value of the variable                                                                       |
|  * `<n>.state`          | `present` (default) or `absent`, create or remove the BB pipeline variables for this account    |
|  * `<n>.secure`         | Is this a secure variable (`yes`) (will not show in BB) or not (`no` - default)                 |

