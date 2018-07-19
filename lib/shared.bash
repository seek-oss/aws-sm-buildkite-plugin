#!/bin/bash

function strip_quotes() {
  echo "${1}" | sed "s/^[ \t]*//g;s/[ \t]*$//g;s/[\"']//g"
}

# AWS SM is only in very recent AWS CLI versions, and isn't on Amazon Linux 2 AMIs (as of July 2018)
docker pull infrastructureascode/aws-cli

function get_secret_value() {
  local secretId="$1"

  # Extract the secret string and secret binary
  read secrets < <(docker run \
    --rm \
    -v ~/.aws:/root/.aws \
    -e 'AWS_ACCESS_KEY_ID' \
    -e 'AWS_SECRET_ACCESS_KEY' \
    -e 'AWS_DEFAULT_REGION' \
    -e 'AWS_REGION' \
    -e 'AWS_SECURITY_TOKEN' \
    -e 'AWS_SESSION_TOKEN' \
    infrastructureascode/aws-cli \
    aws secretsmanager get-secret-value \
      --secret-id "${secretId}" \
      --version-stage AWSCURRENT \
      --output json \
      --query '{SecretString: SecretString, SecretBinary: SecretBinary}')

  # if the secret binary field has a value, assume it's a binary
  read secretBinary < <(echo "${secrets}" | jq -r '.SecretBinary | select(. != null)')
  if [[ -n "${secretBinary}" ]]; then
    echo "${secretBinary}" | base64 --decode
    return
  fi

  # assume it's a string
  echo "${secrets}" | jq -r '.SecretString'
}
