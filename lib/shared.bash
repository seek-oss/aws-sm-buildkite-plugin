#!/bin/bash

function strip_quotes() {
  echo "${1}" | sed "s/^[ \t]*//g;s/[ \t]*$//g;s/[\"']//g"
}

function get_secret_value() {
  local secretId="$1"
  local allowBinary="${2:-}"
  local regionFlag=""

  # secret is an arn rather than name, deduce the region
  local arnRegex='^arn:aws:secretsmanager:([^:]+):'
  if [[ "${secretId}" =~ $arnRegex ]] ; then
    regionFlag="--region ${BASH_REMATCH[1]}"
  fi

  # Extract the secret string and secret binary
  # the secret is declared local before using it, per http://mywiki.wooledge.org/BashPitfalls#local_varname.3D.24.28command.29
  local secrets;
  echo -e "\033[31m" >&2
  secrets=$(aws secretsmanager get-secret-value \
      --secret-id "${secretId}" \
      --version-stage AWSCURRENT \
      $regionFlag \
      --output json \
      --query '{SecretString: SecretString, SecretBinary: SecretBinary}')

  local result=$?
  echo -e "\033[0m" >&2
  if [[ $result -ne 0 ]]; then
    exit 1
  fi

  # if the secret binary field has a value, assume it's a binary
  local secretBinary=$(echo "${secrets}" | jq -r '.SecretBinary | select(. != null)')
  if [[ -n "${secretBinary}" ]]; then
    # don't read binary in cases where it's not allowed
    if [[ "${allowBinary}" == "allow-binary" ]]; then
      echo "${secretBinary}" | base64 -d
      return
    fi
    echo -e "\033[31mBinary encoded secret cannot be used in this way (e.g. env var)\033[0m" >&2
    exit 1
  fi

  # assume it's a string
  echo "${secrets}" | jq -r '.SecretString'
}
