# AWS Secrets Manager Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) to read secrets from AWS Secrets Manager.

Unlike [AWS Systems Manager (AWS SSM) Parameter Store](https://aws.amazon.com/systems-manager/), [AWS Secrets Manager (AWS SM)](https://aws.amazon.com/secrets-manager/) supports:

 - Cross account access without assuming a role; and
 - The ability to setup automatic rotation of secrets

# Setup

This plugins requires AWS CLI version 1.15 or above, as AWS Secrets Manager support is relatively new.

See [AWS Setup](./AWSSETUP.md) for instructions on setting up the provider AWS account, and the build agent permissions.

# Supported Secrets

This plugin supports both `SecretString` and `SecretBinary` [AWS SM secret types](https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html).

## SecretString

A AWS SM secret string may be plaintext or key/value. If you create a key/value secret, then the JSON will be returned. This plugin does not yet support expanding the plugin for you, but `jq` can be used to pull JSON values out.

`SecretString`s can be exposed in an environment variable (`env`) or saved to a file.

## SecretBinary

Binary secrets can be saved to a file. They cannot be used with `env` (as they contain binary data).

# Example

Ensure to escape the variable expression when using it in your steps, e.g. `$$MY_SECRET` or `\$MY_SECRET`. This is due to [how buildkite interpolates variables on pipeline upload](https://buildkite.com/docs/agent/v3/cli-pipeline#environment-variable-substitution):

> If you want an environment variable to be evaluated at run-time (for example, using the step’s environment variables) make sure to escape the $ character using $$ or \$. For example:

## For Secrets in the Same Account

For secrets in the same AWS account as the agent, you can use the secret name rather than the whole ARN.

```yml
steps:
  - commands: 'echo \$MY_SECRET'
    plugins:
      - seek-oss/aws-sm#v1.0.0:
          env:
            MY_SECRET: my-secret-id
            MY_OTHER_SECRET: my-other-secret-id
          file:
            - path: 'save-my-secret-here'
              secret-id: 'my-secret-file-id'
            - path: 'save-my-other-secret-here'
              secret-id: 'my-other-secret-file-id'
```

## For Secrets in Another Account

For secrets in another AWS account, use the secret ARN.

```yml
steps:
  - commands: 'echo \$SECRET_FROM_OTHER_ACCOUNT'
    plugins:
      - seek-oss/aws-sm#v1.0.0:
          env:
            SECRET_FROM_OTHER_ACCOUNT: 'arn:aws:secretsmanager:ap-southeast-2:1234567:secret:my-global-secret'
          file:
            - path: 'save-my-other-secret-here'
              secret-id: 'arn:aws:secretsmanager:ap-southeast-2:1234567:secret:my-global-file-secret'
```

## For Secrets in Another Region

This plugin supports reading AWS SM secrets from a region that is different from where your agents are running. In this case, use the ARN syntax
rather than a secret name. The region will be deduced from the secret ARN.

## Using Secrets in Another Plugin

Per the examples above, the preferred `plugin` YAML syntax is to the use an array of plugins over the object-key syntax, as this ensures consistent ordering between plugins. It's thus possible to use secrets from this plugin in another plugin:

```yml
steps:
  - command: npm publish
    plugins:
      - seek-oss/aws-sm#v1.0.0:
          env:
            MY_TOKEN: npm-publish-token
      - seek-oss/private-npm#v1.1.1:
          env: MY_TOKEN
```

### Docker or Docker Compose

Note that if you're using the [Docker plugin](https://github.com/buildkite-plugins/docker-buildkite-plugin) or [Docker Compose plugin](https://github.com/buildkite-plugins/docker-compose-buildkite-plugin) then the environment variable can be propagated to the container:

```yml
steps:
  - command: echo $$MY_SECRET
    plugins:
      - docker#v1.4.0:
          image: "node:8"
          environment:
            - MY_SECRET # propagates the env var to the container (docker run -e MY_SECRET)
      - seek-oss/aws-sm#v1.0.0:
          env:
            MY_SECRET: the-secret-id
```

# Tests

To run the tests of this plugin, run
```sh
docker-compose run --rm tests
```

# License

MIT (see [LICENSE](LICENSE))
