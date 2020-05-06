#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

environment_hook="$PWD/hooks/environment"
post_checkout_hook="$PWD/hooks/post-checkout"

export SECRET_ID1='secret1'
export SECRET_VALUE1='{"SecretString":"pretty-secret","SecretBinary":null}'
export SECRET_ID2='secret2'
export SECRET_VALUE2='{"SecretString":"{\"nested\":\"secret\"}","SecretBinary":null}'
# hello
export SECRET_ID3='secret3'
export SECRET_VALUE3='{"SecretString":null,"SecretBinary":"aGVsbG8="}'
# world
export SECRET_ID4='secret4'
export SECRET_VALUE4='{"SecretString":null,"SecretBinary":"d29ybGQ="}'
# arn
export SECRET_ID5='arn:aws:secretsmanager:ap-southeast-2:1234567:secret:secret5'
export SECRET_VALUE5='{"SecretString":"secret","SecretBinary":null}'

export SECRET_ID6='secret6'
export SECRET_VALUE6='{"SecretString":"{\"MY_VAR\":\"secret\",\"MY_OTHER_VAR\":\"stuff\"}","SecretBinary":null}'

export SECRET_ID7='secret7'
export JSON_KEY7='.my_key'
export JSON_KEY_WITH_SPACE7='."key with space"'
export SECRET_VALUE7='{"SecretString":"{\"my_key\":{\"NESTED_VAR\":\"secret\",\"OTHER_NESTED_VAR\":\"stuff\"},\"key with space\":{\"NEST\":\"very secret\"}}","SecretBinary":null}'

export SECRET_ID8='secret8'
export SECRET_VALUE8='{"SecretString":"{\"FIRST_SET\":\"secret with a\\nnewline\"}","SecretBinary":null}'
export SECRET_ID9='secret9'
export SECRET_VALUE9='{"SecretString":"{\"SECOND SET\":\"second secret\"}","SecretBinary":null}'

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

@test "Fetches values from AWS SM into env with explicit secret-id" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1_SECRET_ID="${SECRET_ID1}"
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2_SECRET_ID="'${SECRET_ID2}'"

  export -f aws

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading ${SECRET_ID1} from AWS SM into environment variable TARGET1"
  assert_output --partial "Reading ${SECRET_ID2} from AWS SM into environment variable TARGET2"

  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1_SECRET_ID
  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2_SECRET_ID
}

@test "Fetches values from AWS SM into with env with from JSON key" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1="${SECRET_ID1}"
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2_SECRET_ID="'${SECRET_ID2}'"
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2_JSON_KEY=".nested"

  export -f aws

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading ${SECRET_ID1} from AWS SM into environment variable TARGET1"
  assert_output --partial "Reading ${SECRET_ID2} from AWS SM into environment variable TARGET2"

  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET1
  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2_SECRET_ID
  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET2_JSON_KEY
}

@test "Fetches values from AWS SM into env with parsed region" {
  export BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET5="${SECRET_ID5}"

  export -f aws

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading ${SECRET_ID5} from AWS SM into environment variable TARGET5"

  unset BUILDKITE_PLUGIN_AWS_SM_ENV_TARGET5
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

@test "Fetches all environment variables from JSON without JSON key" {
  export BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_SECRET_ID="${SECRET_ID6}"

  export -f aws

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading all environment variables from ${SECRET_ID6} in AWS SM"
  assert_output --partial "Setting environment variable MY_VAR"
  assert_output --partial "Setting environment variable MY_OTHER_VAR"

  unset BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_SECRET_ID
}

@test "Fetches all environment variables from JSON with JSON key" {
  export BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_SECRET_ID="${SECRET_ID7}"
  export BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_JSON_KEY="${JSON_KEY7}"

  export -f aws

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading all environment variables from ${SECRET_ID7} in AWS SM"
  assert_output --partial "Setting environment variable NESTED_VAR"
  assert_output --partial "Setting environment variable OTHER_NESTED_VAR"

  unset BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_SECRET_ID
  unset BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_JSON_KEY
}

@test "Fetches all environment variables from JSON with JSON key that contains a space" {
  export BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_SECRET_ID="${SECRET_ID7}"
  export BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_JSON_KEY="${JSON_KEY_WITH_SPACE7}"

  export -f aws

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading all environment variables from ${SECRET_ID7} in AWS SM"
  assert_output --partial "Setting environment variable NEST"

  unset BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_SECRET_ID
  unset BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_JSON_KEY
}

@test "Fetches all environment variables from multiple JSON secrets" {
  export BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_0_SECRET_ID="${SECRET_ID8}"
  export BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_1_SECRET_ID="${SECRET_ID9}"

  export -f aws

  run "${environment_hook}"

  assert_success
  assert_output --partial "Reading all environment variables from ${SECRET_ID8} in AWS SM"
  assert_output --partial "Setting environment variable FIRST_SET"
  assert_output --partial "Reading all environment variables from ${SECRET_ID9} in AWS SM"
  assert_output --partial "Setting environment variable SECOND_SET"

  unset BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_0_SECRET_ID
  unset BUILDKITE_PLUGIN_AWS_SM_JSON_TO_ENV_1_SECRET_ID
}
