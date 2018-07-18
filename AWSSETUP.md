# Setup

This is a summary of what you can find in the AWS tutorial for [Secrets Manager](https://aws.amazon.com/blogs/aws/aws-secrets-manager-store-distribute-and-rotate-credentials-securely/).

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
