#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

environment_hook="$PWD/hooks/environment"
post_checkout_hook="$PWD/hooks/post-checkout"

export SECRET_ID1='secret1'
export SECRET_VALUE1='{"SecretString":"pretty-secret","SecretBinary":null}'
export SECRET_ID2='secret2'
export SECRET_VALUE2='{"SecretString":"topsecret","SecretBinary":null}'
# hello
export SECRET_ID3='secret3'
export SECRET_VALUE3='{"SecretString":null,"SecretBinary":"aGVsbG8="}'
# world
export SECRET_ID4='secret4'
export SECRET_VALUE4='{"SecretString":null,"SecretBinary":"d29ybGQ="}'

# this is used instead of bats mock, as many of the arguments aren't important
# to assert...
function aws() {
  # echo the secret value based on its id
  read secretNo < <(echo "$@" | grep -o 'secret[0-9]' | grep -o '[0-9]')
  local secretVar="SECRET_VALUE${secretNo}"
  echo "${!secretVar}"
}

@test "Fetches values from AWS SM into env" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1="${SECRET_ID1}"
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2="'${SECRET_ID2}'"

  export -f aws

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading ${SECRET_ID1} from AWS SM into environment variable TARGET1"
  assert_output --partial "Reading ${SECRET_ID2} from AWS SM into environment variable TARGET2"

  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1
  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2
}

@test "Fails if attempting to read binary secret into env var" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1="${SECRET_ID4}"

  export -f aws

  run "${environment_hook}"

  assert_failure
  assert_output --partial "Reading ${SECRET_ID4} from AWS SM into environment variable TARGET1"
  assert_output --partial "Binary encoded secret cannot be used in this way"

  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1
}

@test "Fetches values from AWS SM into file" {
  local test_out_dir="/tmp/aws-sm"
  mkdir -p "${test_out_dir}"
  local path1="${test_out_dir}/path1"
  local path2="${test_out_dir}/path2"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_0_PATH="${path1}"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_0_SECRET_ID="${SECRET_ID1}"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_1_PATH="'${path2}'"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_1_SECRET_ID="'${SECRET_ID3}'"

  export -f aws

  run "${post_checkout_hook}"

  assert_output --partial "Reading ${SECRET_ID1} from AWS SM into file ${path1}"
  assert_output --partial "Reading ${SECRET_ID3} from AWS SM into file ${path2}"
  assert_success

  local actualPath1=$(cat "${path1}")
  local actualPath2=$(cat "${path2}")

  [[ "${actualPath1}" != "pretty-secret" ]] && fail "Expected contents to be saved to file"
  [[ "${actualPath2}" != "hello" ]] && fail "Expected contents to be saved to file"

  unset BUILDKITE_PLUGIN_AWS_SM_FILE_0_PATH
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_0_SECRET_ID
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_1_PATH
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_1_SECRET_ID
}
