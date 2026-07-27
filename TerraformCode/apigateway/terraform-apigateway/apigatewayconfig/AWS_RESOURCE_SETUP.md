# AWS Resource Setup Guide

For each backend type you're testing, this tells you exactly what
to create in the AWS Console and which value goes into which YAML
field. Do this BEFORE writing the YAML — you need these values in
hand first.

Order of operations for every test, regardless of type:
1. Create the AWS resource(s) below.
2. Copy the specific ARNs/IDs/URLs called out.
3. Copy the matching example from `examples/`, paste your real
   values in.
4. `python3 scripts/validate_apis.py apigatewayconfig/apis`
5. `terraform plan`, review, `terraform apply`.
6. Test with curl / wscat / AWS CLI (commands given per section).
7. Move to the next scenario.

---

## 1. Lambda

**Console steps:**
1. Lambda → Create function → "Author from scratch"
2. Runtime: Python 3.12 (or your preference)
3. Create function
4. Paste in test code — use `scripts/echo_lambda.py` (already in
   this repo) for a quick echo/debug Lambda, or your real business
   logic
5. Deploy

**What you copy:** the **Function ARN**, shown at the top-right of
the function's page (`arn:aws:lambda:region:account:function:name`)

**Goes into:** `integrations[].config.function_arn`

**Test it:**
```bash
curl https://<invoke-url>/your-path
```

---

## 2. SQS

**Console steps:**
1. SQS → Create queue → Standard
2. Name it, leave defaults, Create queue
3. IAM → Roles → Create role → Custom trust policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": { "Service": "apigateway.amazonaws.com" },
       "Action": "sts:AssumeRole"
     }]
   }
   ```
4. Attach an inline policy on that role allowing `sqs:SendMessage`
   on the queue's ARN

**What you copy:**
- Queue URL (queue's Details tab) → `request_parameters.QueueUrl`
  (HTTP API) — for REST API, you instead build the `uri` as
  `arn:aws:apigateway:{region}:sqs:path/{account_id}/{queue_name}`
- Role ARN → `config.credentials_arn`

**Test it:**
```bash
curl -X POST https://<invoke-url>/sqs-test -d '{"hello":"world"}'
aws sqs receive-message --queue-url <queue-url>   # confirm it arrived
```

---

## 3. EventBridge

**Console steps:**
1. No queue needed — EventBridge's "default" event bus already
   exists in every account
2. IAM → Roles → Create role → same trust policy as SQS above,
   but the inline policy allows `events:PutEvents` on
   `arn:aws:events:{region}:{account}:event-bus/default`

**What you copy:** Role ARN → `config.credentials_arn`

**Test it:**
```bash
curl -X POST https://<invoke-url>/eventbridge-test -d '{"orderId":"123"}'
```
Confirm via EventBridge → default event bus → set up a temporary
rule that logs to CloudWatch, or check CloudTrail for the PutEvents
call.

---

## 4. ALB (fronting EC2 or ECS)

**Console steps:**
1. EC2 → Launch instance — a plain web server is enough (e.g.
   Amazon Linux with a user-data script installing nginx). Note
   its VPC and subnet.
2. EC2 → Target Groups → Create → type "Instances" → register the
   instance you just launched → protocol/port matching your server
3. EC2 → Load Balancers → Create Application Load Balancer →
   Internal (for private testing) → same VPC, at least 2 subnets
   in different AZs → security group allowing inbound from
   wherever your VPC Link will live → add a listener (HTTP:80)
   forwarding to the target group from step 2

**Then, because of the ALB/VPC-Link caveat above:**
4. Create a second target group, type "ALB", targeting the ALB
   from step 3
5. Create a Network Load Balancer, same VPC/subnets, with a
   listener forwarding to the ALB target group from step 4

**What you copy:** the **NLB's** listener ARN (not the ALB's) →
`integrations[].config.listener_arn`

**VPC Link:** either create one manually (API Gateway console →
VPC Links → Create → point at the NLB) and copy its ID into
`config.vpc_link_id`, or let the module create one for you — see
`examples/04-networking/example2_new_vpc_link.yaml`.

**Test it:**
```bash
curl https://<invoke-url>/alb-test
```

---

## 5. NLB (EKS, or any TCP-level target)

**Console steps (plain EC2/NLB, no Kubernetes):**
1. EC2 → Target Groups → Create → type "Instances", register your
   target(s)
2. EC2 → Load Balancers → Create Network Load Balancer → same VPC
   → listener (TCP, matching your service's port) forwarding to
   that target group

**Console steps (EKS specifically):**
1. If you're using the AWS Load Balancer Controller in your
   cluster, a `Service` of `type: LoadBalancer` with the annotation
   `service.beta.kubernetes.io/aws-load-balancer-type: "nlb"`
   provisions the NLB automatically
2. Find the auto-created NLB in the EC2 → Load Balancers console
   to get its listener ARN

**What you copy:** Listener ARN → `config.listener_arn`

**VPC Link:** same as the ALB section above.

**Test it:**
```bash
curl https://<invoke-url>/nlb-test
```

---

## 6. WebSocket + Lambda

**Console steps:** same as section 1 (Lambda) — reuse the echo
Lambda, or write a small connect/disconnect/message handler.

**Goes into:** `integrations[].config.function_arn`, same as HTTP.

**Test it** (install wscat once: `npm install -g wscat`):
```bash
wscat -c wss://<websocket-invoke-url>
> {"action":"sendMessage","data":"hello"}
```
Watch CloudWatch Logs on the Lambda to confirm `$connect`,
`sendMessage`, and `$disconnect` all fired.

---

## 7. JWT Authorizer (end-to-end security test)

**Console steps:** none needed on the AWS side if you already have
an identity provider (Auth0/Cognito/Okta). You need:
- The issuer URL
- The audience value

**Test it — this is the one that actually proves something:**
```bash
# without a token -- should get 401
curl https://<invoke-url>/jwt-protected

# with a valid token -- should get 200
curl https://<invoke-url>/jwt-protected -H "Authorization: Bearer <real-jwt>"
```
If both of those behave as expected, the authorizer is genuinely
wired end-to-end — not just present in the Terraform plan.

---

## Quick reference — what to copy for each type

| Type | Copy this | Goes into |
|---|---|---|
| LAMBDA | Function ARN | `config.function_arn` |
| SQS (AWS) | Queue URL + Role ARN | `request_parameters.QueueUrl` + `config.credentials_arn` |
| EventBridge (AWS) | Role ARN | `config.credentials_arn` |
| ALB | NLB listener ARN (see caveat) + VPC Link ID | `config.listener_arn` + `config.vpc_link_id` |
| NLB | Listener ARN + VPC Link ID | `config.listener_arn` + `config.vpc_link_id` |
| HTTP | Just the URL | `config.url` |
| JWT | Issuer + audience | `jwt_configuration.issuer` / `.audience` |
