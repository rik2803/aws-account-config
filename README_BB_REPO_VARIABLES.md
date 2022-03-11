# Update all ServiceAccount related repository variables

## IMPORTANT

To remove variables or service accounts for a repo, do not remove the variable
configuration from the BB repo configuration files, as this will not make the
variables disappear in BB.

Instead, add the `state` property and set it to `absent`. If the state property
already exists and is `present`, change it to `absent`.

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

* Retrieve the SSM Secrets with the names `bb_client_id` and `bb_client_secret` for OAuth2
  authentication with BB from the organization's bastion account. See
  [here](https://support.atlassian.com/bitbucket-cloud/docs/use-oauth-on-bitbucket-cloud/)
  for instructions to create the OAuth consumer.
* Retrieve the SSM Secrets with the names `bb_user` and `bb_apitoken` for basic authentication
  with BB from the organization's bastion account.
* The name of the SSM parameters should be:
  * `bb_client_id`
  * `bb_client_secret`
  * `bb_user`
  * `bb_apitoken`
* The config repository for the managed AWS organization should have a file named
  `sa_bb_config.yml` in de `BitbucketRepoConfigs` directory. This file looks like this:

```yaml
tooling_account:
  account_id: "123456789012"
aws_default_region: "eu-central-1"
repos:
{% for include_file in bb_repo_config_include_files | default([]) %}
{%   include 'include/' + include_file %}

{% endfor %}
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

* Repo config files can also live in `./BitbucketRepoConfigs/include/**` in the
  config repository for the managed AWS organization. That allows you to have a single
  configuration file per managed BB repository. That's why the `for` loop is in
  `sa_bb_config.yml`. The content of the files to be included should be indented
  with the correct number of spaces to guarantee that the generated content is
  correct YAML. The name of the YAML files to include should match the name
  of the repository, because the includes are filtered on `limit_bb_repo` as well.

```yaml
  - name: "repo3"
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
  populate the BB pipeline variable
* When cloning `bb-aws-utils` and sourcing `lib.bash`, AWS credentials and config
  files will be created. The first account in the `service_account_list` list will
  also be the default AWS profile. To use any of the other profiles, set and export
  `AWS_DEFAULT_PROFILE` in your pipeline step.
* When `project_key` is not defined, the repo create/update task will be skipped
  to support old repo configs that do not have that property. This behaviour will be
  deprecated in a future version.

## Tags

Tags are used to:

* Speed up the process by limiting the actions to what changed.
* Avoid that the BB API call rate is exceeded.

Following tags are supported:

* `bb_permissions`: Apply group permissions only.
* `bb_serviceaccounts`: Apply all repository variables related to AWS Service Accounts.
* `bb_rotate_credentials`: When the Service Account credentials in the Bastion account are updated
  (this should be done regularly), the BB repository Service Account variables should be updated as
  well. Otherwise, the pipelines will not be able to assume the required permissions.
* `bb_customvars`: Apply custom environment variables only.
* `bb_ssh_keypair`: Apply the SSH key-pair only.
* `bb_datadog`: Apply the DataDog integration environment variables `DD_API_KEY`, `DD_APP_KEY` and `DD_API_HOST`.
* `bb_snyk`: Apply the Snyk token used to integrate Snyk checks in pipelines,

## The configuration file

| Property               | Description                                                                                        |
|------------------------|----------------------------------------------------------------------------------------------------|
| `tooling-account`      | The AWS account ID where _global_ artifacts are stored                                             |
| `aws_default_region`   | The default region for the AWS profiles                                                            |
| `project_key`          | The key of the project the repository should be assigned to                                        |
| `group_permissions`    | Group permissions to add to the repo                                                               |
| * `<n>.group_slug`     | The Group Slug to grant permissions for                                                            |
| * `<n>.privilege`      | The privilege to grant, should be one of `read`, `write` or `admin`                                |
| `service_account_list` | List of dicts for the accounts for which to create BB pipeline variables                           |
| * `<n>.name`           | The name of the account, this will be used to retrieve the secrets from the SSM Parameter store    |
| * `<n>.role_to_assume` | The role to assume on the account, defaults to `cicd`                                              |
| * `<n>.state`          | `present` (default) or `absent`, create or remove the BB pipeline variables for this account       |
| `custom_vars`          | List of `name`/`value` dicts to create other BB pipeline variables                                 |
| * `<n>.name`           | The name of the variable                                                                           |
| * `<n>.value`          | The value of the variable                                                                          |
| * `<n>.state`          | `present` (default) or `absent`, create or remove the BB pipeline variables for this account       |
| * `<n>.secure`         | Is this a secure variable (`yes`) (will not show in BB) or not (`no` - default)                    |
| `branch_restrictions`  | List of branch restrictions, see BB API docs for the syntax (and should be converted to YAML)      |
| `branching_model`      | (WIP) Branching model to apply, see BB API docs for the syntax (and should be converted to YAML)   |
| `language`             | Optional, defaults to `java` (`java`, `javascript`, `nodejs`, `typescript`, `shell`, `python`, ... |

### What it does

The goal is to fully manage the lifecycle of a BitBucket repository.

* Create or update the repository
* Set branch restrictions if the repository has just been created
* Set branching model (Work In Progress)
* Set group permissions
* Create a template `README.md` file (and implicitly the `mastrer` branch)
* Set the project language (default `java`)
* Enable pipelines, but only if the `service_account_list` property is set.
* Set pipeline environment variables:
  * For AWS SA accounts if the `service_account_list` property is set.
  * Custom variables
  
The `branch_restrictions` and `branching_model` can be specified:

* Somewhere as a toplevel variable `bitbucket.default_branch_restrictions` or `bitbucket.default_branching_model`.
* The toplevel config can be overridden in the repository configuration.

The BB group `default-reviewers` (if it exists) will always be granted write permissions on a repo, as the
group members should be able to review repo PRs.

The toplevel property `bitbucket.default_reviewers` is also required, as they are configured as the default
reviewers for a repository. When you want to remove a user from the default reviewers list, change the state
to `absent` rather than removing it from the list entirely. In the latter case, the user will remain in the
default reviewers list when updating the repo config.

```bash
bitbucket:
  default_reviewers:
    - uuid: "{user uuid}"
      name: "Firstname Lastname"
      state: "present"
```

### An example

```yml
  - name: "my-repo"
    project_key: "PROJ_KEY"
    group_permissions:
      - group_slug: "good-project-developers"
        privilege: "write"
      - group_slug: "bad-project-developers"
        privilege: "read"
      - group_slug: "project-admins"
        privilege: "admin"
    service_account_list:
      - name: "TOOLING"
      - name: "DEV"
      - name: "STG"
      - name: "PRD"
    custom_vars:
      - name: "A_VARIABLE"
        description: "A variable"
        value: "a value"
        secret: "false"
      - name: "A_SECRET_VARIABLE"
        description: "A secret variable"
        value: "a secret value"
        secret: "true"
    branch_restrictions:
      - kind: push
        branch_match_kind: glob
        pattern: "master"
        users:
          - uuid: "{user uuid}"
      - kind: push
        branch_match_kind: glob
        pattern: "hotfix/*"
        users:
          - uuid: "{user uuid}"
      - kind: delete
        branch_match_kind: glob
        pattern: "master"
      - kind: delete
        branch_match_kind: glob
        pattern: "hotfix/*"
      - kind: force
        branch_match_kind: glob
        pattern: "master"
      - kind: force
        branch_match_kind: glob
        pattern: "hotfix/*"
      - kind: require_passing_builds_to_merge
        branch_match_kind: glob
        pattern: "master"
        value: 1
      - kind: require_passing_builds_to_merge
        branch_match_kind: glob
        pattern: "hotfix/*"
        value: 1
      - kind: require_approvals_to_merge
        branch_match_kind: glob
        pattern: "master"
        value: 1
      - kind: require_approvals_to_merge
        branch_match_kind: glob
        pattern: "hotfix/*"
        value: 1
      - kind: require_default_reviewer_approvals_to_merge
        branch_match_kind: glob
        pattern: "master"
        value: 1
      - kind: require_default_reviewer_approvals_to_merge
        branch_match_kind: glob
        pattern: "hotfix/*"
        value: 1
      - kind: reset_pullrequest_approvals_on_change
        branch_match_kind: glob
        pattern: "master"
      - kind: reset_pullrequest_approvals_on_change
        branch_match_kind: glob
        pattern: "hotfix/*"
  default_branching_model:
    development:
      name:
      use_mainbranch: true
    production:
      name:
      use_mainbranch: true
    branch_types:
      - kind: "release"
        prefix: "release/"
      - kind: "hotfix"
        prefix: "hotfix/"
      - kind: "feature"
        prefix: "feature/"
      - kind: "bugfix"
        prefix: "bugfix/"
```
