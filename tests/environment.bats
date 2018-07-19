#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

environment_hook="$PWD/hooks/environment"

function stub_secret_plan() {
  local secretId="${1}"
  local secretJson="${2}"
  echo "run --rm -v ~/.aws:/root/.aws -e 'AWS_ACCESS_KEY_ID' -e 'AWS_SECRET_ACCESS_KEY' -e 'AWS_DEFAULT_REGION' -e 'AWS_REGION' -e 'AWS_SECURITY_TOKEN' -e 'AWS_SESSION_TOKEN' infrastructureascode/aws-cli aws secretsmanager get-secret-value --secret-id ${secretId} --version-stage AWSCURRENT --output json --query '{SecretString: SecretString, SecretBinary: SecretBinary}' : echo ${secretJson}"
}

@test "Fetches values from AWS SM into env" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1='SECRET_ID1'
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2="'SECRET_ID2'"

  local secretValue1='{SecretString:"secret"}'
  local secretValue2='{SecretString:"secret"}'

  # the stub plan has to be declared at the same time (e.g. can't stub docker multiple times)
  stub docker \
    "pull infrastructureascode/aws-cli : echo ran docker pull" \
    stub_secret_plan 'SECRET_ID1' "${secretValue1}" \
    stub_secret_plan 'SECRET_ID2' "${secretValue2}"

  stub jq \
    "-r '.SecretBinary | select(. != null)' : echo ''" \
    "-r '.SecretString' : echo 'secret'"

  run "${environment_hook}"

  assert_output --partial "Reading SECRET_ID1 from AWS SM into environment variable TARGET1"
  assert_output --partial "Reading SECRET_ID2 from AWS SM into environment variable TARGET2"
  assert_output --partial "ran docker pull"
  assert_success

  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1
  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2
}

@test "Fetches values from AWS SM into file" {
  local test_out_dir="/tmp/aws-sm"
  mkdir -p "${test_out_dir}"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_0=''
  export BUILDKITE_PLUGIN_AWS_SM_FILE_0_PATH="${test_out_dir}/path1"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_0_SECRET_ID='SECRET_ID1'
  export BUILDKITE_PLUGIN_AWS_SM_FILE_1=''
  export BUILDKITE_PLUGIN_AWS_SM_FILE_1_PATH="'${test_out_dir}/path2'"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_1_SECRET_ID="'SECRET_ID2'"

  local secretValue1='{SecretBinary:"secretbase64"}'
  local secretValue2='{SecretString:"secret"}'

  # the stub plan has to be declared at the same time (e.g. can't stub docker multiple times)
  stub docker \
    "pull infrastructureascode/aws-cli : echo ran docker pull" \
    stub_secret_plan 'SECRET_ID1' "${secretValue1}" \
    stub_secret_plan 'SECRET_ID2' "${secretValue2}"

  stub jq \
    "-r '.SecretBinary | select(. != null)' : echo ''" \
    "-r '.SecretString' : echo 'secret'"

  stub base64 \
    "--decode : echo 'final secret'"

  run "${environment_hook}"

  assert_output --partial "Reading SECRET_ID1 from AWS SM into file ${test_out_dir}/path1"
  assert_output --partial "Reading SECRET_ID2 from AWS SM into file ${test_out_dir}/path2"
  assert_output --partial "ran docker pull"
  assert_success

  unset BUILDKITE_PLUGIN_AWS_SM_FILE_0
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_0_PATH
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_0_SECRET_ID
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_1
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_1_PATH
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_1_SECRET_ID
}
