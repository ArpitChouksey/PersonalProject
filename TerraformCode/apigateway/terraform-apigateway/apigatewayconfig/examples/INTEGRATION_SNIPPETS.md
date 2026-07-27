# Minimal Integration Reference

Copy the block for whatever backend you're pointing at into your
YAML's `integrations:` list. These are the *only* fields required
per type — everything else in the full template is optional.

---

## Lambda

```yaml
integrations:
  - name: my-lambda
    type: LAMBDA
    config:
      function_arn: arn:aws:lambda:us-west-2:111111111111:function:my-function
```

---

## Internal ALB (also how ECS / EC2 backends are reached)

```yaml
integrations:
  - name: my-alb
    type: ALB
    config:
      listener_arn: arn:aws:elasticloadbalancing:us-west-2:111111111111:listener/app/my-alb/abc123
      vpc_link_id: vpclink-123456
```

---

## Internal NLB (also how EKS backends are reached)

```yaml
integrations:
  - name: my-nlb
    type: NLB
    config:
      listener_arn: arn:aws:elasticloadbalancing:us-west-2:111111111111:listener/net/my-nlb/abc123
      vpc_link_id: vpclink-123456
```

---

## Public/Private HTTP endpoint

```yaml
integrations:
  - name: my-http
    type: HTTP
    config:
      url: https://api.example.com
```

---

## AWS Service — HTTP or WebSocket API

```yaml
integrations:
  - name: my-service
    type: AWS
    config:
      integration_subtype: EventBridge-PutEvents   # or SQS-SendMessage, S3-PutObject, etc.
      credentials_arn: arn:aws:iam::111111111111:role/apigw-service-role
```

## AWS Service — REST API

REST (v1) integrations need a full target URI instead of the
shorthand above:

```yaml
integrations:
  - name: my-service
    type: AWS
    config:
      uri: arn:aws:apigateway:us-west-2:sqs:path/111111111111/my-queue
      credentials_arn: arn:aws:iam::111111111111:role/apigw-service-role
```

---

Then reference the integration by `name` from any route:

```yaml
routes:
  - path: /hello
    method: GET
    integration: my-lambda
```
