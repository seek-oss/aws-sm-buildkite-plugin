#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

environment_hook="$PWD/hooks/environment"

export SECRET_ID1='secret1'
export SECRET_VALUE1='{"SecretString":"pretty-secret","SecretBinary":null}'
export SECRET_ID2='secret2'
export SECRET_VALUE2='{"SecretString":"topsecret","SecretBinary":null}'
export SECRET_ID3='secret3'
export SECRET_VALUE3='{"SecretString":null,"SecretBinary":"base64-secret"}'

# this is used instead of bats mock, as many of the arguments aren't important
# to assert...
function docker() {
  if [[ "$1" != "run" ]]; then
    echo "ran docker $1"
    return
  fi

  # echo the secret value based on its id
  read secretNo < <(echo "$@" | grep -o 'secret[0-9]' | grep -o '[0-9]')
  local secretVar="SECRET_VALUE${secretNo}"
  echo "${!secretVar}"
}

@test "Fetches values from AWS SM into env" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1="${SECRET_ID1}"
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2="'${SECRET_ID2}'"

  export -f docker

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading ${SECRET_ID1} from AWS SM into environment variable TARGET1"
  assert_output --partial "Reading ${SECRET_ID2} from AWS SM into environment variable TARGET2"
  assert_output --partial "ran docker pull"

  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1
  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2
}

@test "Fetches values from AWS SM into file" {
  local test_out_dir="/tmp/aws-sm"
  mkdir -p "${test_out_dir}"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_0=''
  export BUILDKITE_PLUGIN_AWS_SM_FILE_0_PATH="${test_out_dir}/path1"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_0_SECRET_ID="${SECRET_ID1}"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_1=''
  export BUILDKITE_PLUGIN_AWS_SM_FILE_1_PATH="'${test_out_dir}/path2'"
  export BUILDKITE_PLUGIN_AWS_SM_FILE_1_SECRET_ID="'${SECRET_ID3}'"

  export -f docker

  run "${environment_hook}"

  assert_output --partial "Reading ${SECRET_ID1} from AWS SM into file ${test_out_dir}/path1"
  assert_output --partial "Reading ${SECRET_ID3} from AWS SM into file ${test_out_dir}/path2"
  assert_output --partial "ran docker pull"
  assert_success

  unset BUILDKITE_PLUGIN_AWS_SM_FILE_0
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_0_PATH
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_0_SECRET_ID
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_1
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_1_PATH
  unset BUILDKITE_PLUGIN_AWS_SM_FILE_1_SECRET_ID
}
