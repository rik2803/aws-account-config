#!/bin/bash

declare -a all_tags=(
  'accountalias:Create account aliases'
  'assign_users_to_groups'
  'basic'
  'bastion'
  'bastion_create_codeartifact_accounts'
  'bastion_create_ecr_deploy_users:Create deploy users with ECR permissions on '
  'bastion_create_service_accounts:Create service accounts on the bastion account'
  'bastion_custom_groups'
  'bastion_grouppolicy'
  'bastion_groups'
  'billing'
  'codeartifact'
  'create_aws_account_policy'
  'create_users:Create users on the bastion account'
  'createroles:Create roles on subaccounts that can be assumed from the bastino account'
  'html'
  'keypair'
  'monitoring'
  'monitoring_bastion'
  'monitoring_subaccount'
  'organization'
  'passwordpolicy'
  'security'
  'security_guardduty'
  'security_subaccount'
  'security_subaccount_service_accounts'
  'securityaccount'
  'servicelinkedrole'
  'ssm_parameters:Provision SSM parameters on all accounts'
  'subaccounts'
  'tooling'
  'bastion_create_ecr_deploy_users+tooling:'
)