# AWS Secrets Manager Buildkite Plugin

[![GitHub Release](https://img.shields.io/github/release/seek-oss/aws-sm-buildkite-plugin.svg)](https://github.com/seek-oss/aws-sm-buildkite-plugin/releases)

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) to read secrets from AWS Secrets Manager.

Unlike [AWS Systems Manager (AWS SSM) Parameter Store](https://aws.amazon.com/systems-manager/), [AWS Secrets Manager (AWS SM)](https://aws.amazon.com/secrets-manager/) supports:

- Cross account access without assuming a role; and
- The ability to setup automatic rotation of secrets

## Setup

This plugins requires AWS CLI version 1.15 or above, as AWS Secrets Manager support is relatively new.

See [AWS Setup](./AWSSETUP.md) for instructions on setting up the provider AWS account, and the build agent permissions.

## Supported Secrets

This plugin supports both `SecretString` and `SecretBinary` [AWS SM secret types](https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html).

### SecretString

A AWS SM secret string may be plaintext or key/value. **If you create a key/value secret, then the JSON will be returned.**

`SecretString`s can be exposed in an environment variable (`env`) or saved to a file.

This plugin supports expanding the secret JSON for you, which saves you from having to use `jq` pull JSON values out.

### SecretBinary

Binary secrets can be saved to a file.
They cannot be used with `env` (as they contain binary data).

## Examples

Ensure to escape the variable expression when using it in your steps, e.g. `$$MY_SECRET` or `\$MY_SECRET`.
This is due to [how buildkite interpolates variables on pipeline upload](https://buildkite.com/docs/agent/v3/cli-pipeline#environment-variable-substitution):

> If you want an environment variable to be evaluated at run-time (for example, using the step’s environment variables) make sure to escape the $ character using $$ or \$. For example:

### For Secrets in the Same Account

For secrets in the same AWS account as the agent, you can use the secret name rather than the whole ARN.

```yml
steps:
  - commands: 'echo \$MY_SECRET'
    plugins:
      - seek-oss/aws-sm#v2.4.1:
          env:
            MY_SECRET: my-secret-id
            MY_OTHER_SECRET: my-other-secret-id
          file:
            - path: "save-my-secret-here"
              secret-id: "my-secret-file-id"
            - path: "save-my-other-secret-here"
              secret-id: "my-other-secret-file-id"
```

### For Secrets in JSON

For Secrets in JSON (e.g. you're using AWS SMs key=value support), a `jq`-compatible json-key can be specified:

```yml
steps:
  - commands: 'echo \$MY_SECRET'
    plugins:
      - seek-oss/aws-sm#v2.4.1:
          env:
            MY_SECRET:
              secret-id: "my-secret-id"
              json-key: ".Password"
            MY_OTHER_SECRET: my-other-secret-id
```

### To apply all keys in a JSON secret as environment variables

```yml
steps:
  - commands: 'echo \$MY_SECRET'
    plugins:
      - seek-oss/aws-sm#v2.4.1:
          json-to-env:
            - secret-id: "my-secret-id"
              json-key: ".Variables"
```

With the above setting, a secret called `my-secret-id` with the contents:

```json
{
  "Variables": {
    "MY_SECRET": "value",
    "MY_OTHER_SECRET": "other value"
  }
}
```

would set the `MY_SECRET` and `MY_OTHER_SECRET` environment variables.

Some points of note:

- JSON keys are mapped into environment variables by replacing special characters with `_`.
  E.g. `My-great key!` would become `My_great_key_`
- JSON keys with spaces are supported via `json-key: '."My key with a space"'` per normal jq syntax

### For Secrets in Another Account

For secrets in another AWS account, use the secret ARN.

```yml
steps:
  - commands: 'echo \$SECRET_FROM_OTHER_ACCOUNT'
    plugins:
      - seek-oss/aws-sm#v2.4.1:
          env:
            SECRET_FROM_OTHER_ACCOUNT: "arn:aws:secretsmanager:ap-southeast-2:1234567:secret:my-global-secret"
          file:
            - path: "save-my-other-secret-here"
              secret-id: "arn:aws:secretsmanager:ap-southeast-2:1234567:secret:my-global-file-secret"
```

### For Secrets in Another Region

This plugin supports reading AWS SM secrets from a region that is different from where your agents are running.
In this case, you can either use the ARN syntax to deduce the region from the secret ARN or you can set it directly using the `region` parameter.

```yml
steps:
  - commands: 'echo \$SECRET_FROM_OTHER_REGION'
    plugins:
      - seek-oss/aws-sm#v2.4.1:
          region: us-east-1
          env:
            SECRET_FROM_OTHER_REGION: my-secret-id
```

### For use with VPC Endpoints

You may want to specify a custom `endpoint-url` if you are using a [VPC endpoint](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html)
for increased security.

```yml
steps:
  - commands: 'echo \$MY_SECRET'
    plugins:
      - seek-oss/aws-sm#v2.4.1:
          endpoint-url: https://vpce-12345-abcd.secretsmanager.us-east-1.vpce.amazonaws.com
          env:
            MY_SECRET: my-secret-id
```

<<<<<<< HEAD

### Secret Redaction

By default, this plugin automatically registers all loaded secrets with [Buildkite's secret redactor](https://buildkite.com/docs/agent/v3/cli/reference/redactor) to prevent accidental exposure in build logs. This ensures that if secrets are printed later in your build commands, they will be automatically redacted.

You can disable this behavior by setting `redact-secrets: false`:

```yml
steps:
  - commands: 'echo \$MY_SECRET'
    plugins:
      - seek-oss/aws-sm#v2.4.1:
          redact-secrets: false
          env:
            MY_SECRET: my-secret-id
```

=======

> > > > > > > parent of 3ce741c (Automatically redact secrets using buildkite-agent redactor add (#37))

### Using Secrets in Another Plugin

Per the examples above, the preferred `plugin` YAML syntax is to use an array of plugins over the object-key syntax, as this ensures consistent ordering between plugins.
It's thus possible to use secrets from this plugin in another plugin:

```yml
steps:
  - command: npm publish
    plugins:
      - seek-oss/aws-sm#v2.4.1:
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
      - seek-oss/aws-sm#v2.4.1:
          env:
            MY_SECRET: the-secret-id
      - docker#v1.4.0:
          image: "node:8"
          environment:
            - MY_SECRET # propagates the env var to the container (docker run -e MY_SECRET)
```

## Tests

To run the tests of this plugin, run

```sh
docker-compose run --rm tests
```

## License

MIT (see [LICENSE](LICENSE))
