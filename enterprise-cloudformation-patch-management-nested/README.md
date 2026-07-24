# Enterprise CloudFormation Patch Management - Nested Stack Edition

Same 12 modules as the sibling-stack version, restructured as **nested
stacks** under one root stack (`main.yaml`). If you've used Terraform,
this maps directly:

| Terraform | This project |
|---|---|
| `module "network" { source = "./modules/network" }` | `NetworkStack:` resource in `main.yaml`, `TemplateURL: .../network.yaml` |
| Module input variables | The `Parameters:` block passed into each nested stack |
| `module.network.vpc_id` | `!GetAtt NetworkStack.Outputs.VpcId` |
| `terraform apply` | `aws cloudformation deploy --template-file templates/main.yaml ...` |
| `terraform destroy` | `aws cloudformation delete-stack --stack-name epm-dev` |

You deploy **one stack** (`main.yaml`). CloudFormation reads the `GetAtt`
references between the 12 nested stacks and works out the creation order
itself - the `deploy-all.sh` script from the sibling-stack version isn't
needed anymore.

## The one real difference from Terraform modules

Terraform module `source` can be a local folder. CloudFormation's
`TemplateURL` **must** point to S3 - there's no "local path" option for
nested stacks. So there's one extra step Terraform doesn't require:
uploading the child templates first.

## Deploying

```bash
cd enterprise-cloudformation-patch-management-nested

# 1. Create or reuse a bucket to hold the child templates
aws s3 mb s3://your-artifacts-bucket

# 2. Upload every child template EXCEPT main.yaml (main.yaml stays local -
#    it's the root template you pass to --template-file, not fetched from S3)
aws s3 cp templates/ s3://your-artifacts-bucket/templates/ --recursive --exclude "main.yaml"

# 3. Fill in your bucket name in parameters/main-dev.json, then deploy
#    the root stack - this is the ENTIRE deployment, one command:
aws cloudformation deploy \
  --template-file templates/main.yaml \
  --stack-name epm-dev \
  --parameter-overrides file://parameters/main-dev.json \
  --capabilities CAPABILITY_NAMED_IAM
```

That single `deploy` call creates all 12 nested stacks, in the correct
order, automatically. Confirm the SNS email subscription afterward (still
a manual click - no way around that one).

## Tearing down

```bash
aws cloudformation delete-stack --stack-name epm-dev
aws cloudformation wait stack-delete-complete --stack-name epm-dev
```

One command deletes the root stack **and all 12 nested stacks**, in
reverse order, automatically - just like `terraform destroy`.

Note: the report S3 bucket has `DeletionPolicy: Retain`, so it survives
stack deletion on purpose (compliance data shouldn't vanish because you
tore down a test environment). Delete it manually if you don't need it:
```bash
aws s3 rb s3://epm-dev-patch-reports-<account-id> --force
```

## Viewing the nested stacks

In the CloudFormation console, open `epm-dev` and toggle **"View nested"**
in the Stacks list - each of the 12 shows up as its own stack underneath
the root, exactly like a Terraform module shows up as a distinct group of
resources in `terraform state list`.

## What changed vs. the sibling-stack version

Five templates had their `Fn::ImportValue` lookups replaced with plain
`Parameters`, since nested stacks pass values down directly instead of
through account-wide Exports:

- `compute.yaml` - now takes `PublicSubnet1Id`, `PublicSubnet2Id`,
  `SecurityGroupId`, `InstanceProfileName` as Parameters
- `state-manager.yaml` - now takes `InstallAgentDocumentName`
- `cloudwatch.yaml` - now takes `NotificationTopicArn` and all 4 instance IDs
- `eventbridge.yaml` - now takes `NotificationTopicArn`
- `maintenance-window.yaml` - now takes `PatchOrchestrationRunbookName`,
  `ReportBucketName`, `NotificationTopicArn`

`network.yaml`, `iam.yaml`, `ssm.yaml`, `patch-manager.yaml`,
`reporting.yaml`, `sns.yaml`, and `inventory.yaml` are unchanged - they
never needed anything from another stack, so there was nothing to convert.

## Trade-off worth knowing

Nested stacks are great for "deploy as one unit" projects like this one.
They're a worse fit if you ever want to update just one module (say,
`cloudwatch.yaml`) independently without touching the others - with the
sibling-stack version you could `aws cloudformation deploy` just that one
file; with nested stacks, any change still goes through an update to the
root stack (CloudFormation only actually touches the changed nested
stack's resources, but you're still running the update through
`main.yaml`). Keep both versions around and pick per use case - this
isn't a strict upgrade, just a different shape.
