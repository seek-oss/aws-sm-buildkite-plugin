#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

environment_hook="$PWD/hooks/environment"

docker() {
  echo "ran docker $1"
}

jq() {
  echo "ran jq"
}

base64() {
  echo "ran base64"
}

@test "Fetches values from AWS SM into env" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1='SECRET_ID1'
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2="'SECRET_ID2'"

  export -f docker
  export -f jq
  export -f base64

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

  export -f docker
  export -f jq
  export -f base64

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
