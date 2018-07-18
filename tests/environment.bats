#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

environment_hook="$PWD/hooks/environment"

docker() {
  echo "ran docker $1"
}

@test "Fetches values from AWS SM" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_0='TARGET1=SECRET_ID1'
  export BUILDKITE_PLUGIN_AWS_SM_ENV_1="TARGET2='SECRET_ID2'"

  export -f docker

  run "${environment_hook}"

  assert_output --partial "Reading SECRET_ID1 from AWS SM into TARGET1"
  assert_output --partial "Reading SECRET_ID2 from AWS SM into TARGET2"
  assert_output --partial "ran docker pull"
  assert_success

  unset BUILDKITE_PLUGIN_AWS_SM_ENV_0
  unset BUILDKITE_PLUGIN_AWS_SM_ENV_1
}
