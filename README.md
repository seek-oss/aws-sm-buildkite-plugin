# AWS Secrets Manager Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) to read secrets from AWS Secrets Manager.

Unlike [AWS Systems Manager (AWS SSM) Parameter Store](https://aws.amazon.com/systems-manager/), [AWS Secrets Manager (AWS SM)](https://aws.amazon.com/secrets-manager/) supports:

 - Cross account access without assuming a role; and
 - The ability to setup automatic rotation of secrets

# Setup

See [AWS Setup](./AWSSETUP.md) for instructions on setting up the provider AWS account, and the build agent permissions.


# Example

## For Secrets in the Same Account

For secrets in the same AWS account as the agent, you can use the secret name rather than the whole ARN.

```yml
steps:
  - commands: 'echo \$MY_SECRET'
    plugins:
      seek-oss/aws-sm#v0.0.2:
        env:
          MY_SECRET: my-secret-id
          MY_OTHER_SECRET: my-other-secret-id
```

## For Secrets in Another Account

For secrets in another AWS account, use the secret ARN.

```yml
steps:
  - commands: 'echo \$SECRET_FROM_OTHER_ACCOUNT'
    plugins:
      seek-oss/aws-sm#v0.0.2:
        env:
          SECRET_FROM_OTHER_ACCOUNT: 'arn:aws:secretsmanager:ap-southeast-2:1234567:secret:my-global-secret'
```

# Tests

To run the tests of this plugin, run
```sh
docker-compose run --rm tests
```

# License

MIT (see [LICENSE](LICENSE))
