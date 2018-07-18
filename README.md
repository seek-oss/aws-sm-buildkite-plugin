# AWS Secrets Manager Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) to read secrets from AWS Secrets Manager.

# Setup

Unlike [AWS Systems Manager (AWS SSM) Parameter Store](https://aws.amazon.com/systems-manager/), [AWS Secrets Manager (AWS SM)](https://aws.amazon.com/secrets-manager/) supports:

 - Cross account access without assuming a role; and
 - The ability to setup automatic rotation of secrets

## 1. Provider Account

Setup the AWS Account that will share the secrets with your agents, this may be the same account your agents run in or another account.

### Create the Secrets

You can do this via the AWS Console or the AWS CLI:

```
$ aws secretsmanager create-secret --name my-secret --secret-string 'CHANGE_ME'
$ aws secretsmanager create-secret --name my-other-secret --secret-string 'CHANGE_ME'
```

### Create a Policy for the Secrets

The policy lets you access the secrets from your build agents, note that the resource of `*` just means "the current secret" (not all secrets).

`secrets-policy.json`
```json
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::<BUILD AGENT ACCOUNT ID>:role/buildkite-Role"},
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringEquals": {
          "secretsmanager:VersionStage": "AWSCURRENT"
        }
      }
    }
  ]
}
```

Attach the policy to the secrets:
```
$ aws secretsmanager put-resource-policy --secret-id my-secret-id --resource-policy file://secrets-policy.json
$ aws secretsmanager put-resource-policy --secret-id my-other-secret-id --resource-policy file://secrets-policy.json
```

## 2. Build Agent Policy

The build agents will need permissions to read the secret, and use the KMS key to decrypt the secrets. The
build agents should have these statements in their managed policy:

```
  - Sid: AllowReadOfSecrets
    Effect: Allow
    Action:
      - secretsmanager:GetSecretValue
    Resource:
      - !Sub 'arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:my-secret-id-*'
      - !Sub 'arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:my-other-secret-id-*'
  - Sid: AllowKmsDecryptOfSecrets
    Effect: Allow
    Action:
      - kms:Decrypt
    # Specify a different KMS key id if you didn't use the default
    Resource: 'arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/0000-0000-0000-0000'
```

# Example

## For Secrets in the Same Account

For secrets in the same AWS account as the agent, you can use the secret name rather than the whole ARN.

```yml
steps:
  - commands: 'echo $MY_SECRET'
    plugins:
      seek-oss/aws-sm#v0.0.1:
        env:
          - MY_SECRET='my-secret-id'
          - MY_OTHER_SECRET='my-other-secret-id'
```

## For Secrets in Another Account

For secrets in another AWS account, use the secret ARN.

```yml
steps:
  - commands: 'echo $SECRET_FROM_OTHER_ACCOUNT'
    plugins:
      seek-oss/aws-sm#v0.0.1:
        env:
          - SECRET_FROM_OTHER_ACCOUNT='arn:aws:secretsmanager:ap-southeast-2:1234567:secret:my-global-secret'
```

# Tests

To run the tests of this plugin, run
```sh
docker-compose run --rm tests
```

# License

MIT (see [LICENSE](LICENSE))
