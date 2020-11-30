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

## How it works?

* Retrieve the SSM Secrets with the `client_id` and `secret_id` for OAuth2
  authentication with BB
* Retrieve all `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` from
  the output of the _CloudFormation_ stack 
* The file `xxx.yml` contains the configuration
