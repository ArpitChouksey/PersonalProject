# Example Library — Find Your Scenario, Copy the File

**How to use this:** find the row that matches what someone asked
you for, open that file, copy it, fill in the placeholders (ARNs,
URLs, names), save into `apigatewayconfig/apis/`. Every file here
is self-contained and already passes `scripts/validate_apis.py`.

If a request combines several rows (e.g. "REST API, with JWT auth,
behind a custom domain"), open all matching files and merge their
relevant sections into one file — each example only demonstrates
its ONE topic in isolation so you can see clearly which lines
belong to which concern.

---

## "What kind of API is this?"

| They said... | Open this file |
|---|---|
| "just a normal API" / "basic CRUD" / default choice if unsure | `01-api-types/example1_HTTP_API.yaml` |
| "we need API keys" / "usage limits for partners" / "quotas" | `01-api-types/example2_REST_API.yaml` |
| "real-time" / "chat" / "live updates" / "stays connected" | `01-api-types/example3_WEBSOCKET_API.yaml` |

## "What does it actually call / connect to?"

| They said... | Open this file |
|---|---|
| "it's a Lambda function" | `02-backend-integrations/example1_LAMBDA.yaml` |
| "it's on ECS" / "it's on EC2" / "it's behind an ALB" | `02-backend-integrations/example2_ALB.yaml` |
| "it's running on Kubernetes / EKS" / "behind an NLB" | `02-backend-integrations/example3_NLB.yaml` |
| "it's another website" / "an external API" / "just proxy this URL" | `02-backend-integrations/example4_HTTP_URL.yaml` |
| "send it straight to SQS, no Lambda" (HTTP/WebSocket API) | `02-backend-integrations/example5_AWS_SERVICE_SQS.yaml` |
| same as above, but it's a REST API | `02-backend-integrations/example6_AWS_SERVICE_REST.yaml` |

*(EventBridge, Step Functions, S3, DynamoDB etc. follow the exact same shape as the SQS examples — just change `integration_subtype`/`uri` and `request_parameters`. See `INTEGRATION_SNIPPETS.md` for the field names per service.)*

## "Does this need a login / access check?"

| They said... | Open this file |
|---|---|
| "users log in with a token (Auth0/Okta/etc)" — HTTP API | `03-authorizers/example1_JWT_HTTP.yaml` |
| "we have our own custom auth logic" — HTTP API | `03-authorizers/example2_LAMBDA_REQUEST_HTTP.yaml` |
| "we have our own custom auth logic" — REST API | `03-authorizers/example3_LAMBDA_TOKEN_REST.yaml` |
| "we already use AWS Cognito" — REST API only | `03-authorizers/example4_COGNITO_REST.yaml` |
| "only other AWS services should call this, no end users" | `03-authorizers/example5_IAM.yaml` |
| "no login needed, fully public" | `03-authorizers/example6_NO_AUTH.yaml` |

## "Does it need to reach something inside our VPC?"

| They said... | Open this file |
|---|---|
| "a VPC Link already exists for this load balancer" | `04-networking/example1_existing_vpc_link.yaml` |
| "no VPC Link exists yet, set one up" | `04-networking/example2_new_vpc_link.yaml` |
| "this should never be reachable from the public internet" | `04-networking/example3_private_api.yaml` |

## "Any other security requirements?"

| They said... | Open this file |
|---|---|
| "give partners API keys" / "cap how many calls they can make" | `05-security/example1_api_keys_and_usage_plan.yaml` |
| "protect against bots / common web attacks" | `05-security/example2_waf.yaml` |
| "caller must present a trusted client certificate" | `05-security/example3_mutual_tls.yaml` |

## "Custom domain?"

| They said... | Open this file |
|---|---|
| "we want api.company.com instead of the ugly AWS URL" | `06-domain/example1_custom_domain_route53.yaml` |

## "Do we already have an OpenAPI/Swagger spec?"

| They said... | Open this file |
|---|---|
| "we already have a Swagger/OpenAPI file (Postman, Stoplight, design-first, or legacy)" — REST API only | `08-openapi-import/example1_swagger_import.yaml` |

## "Logging / observability?"

| They said... | Open this file |
|---|---|
| "we need to see what's hitting this and debug failures" | `07-logging/example1_access_logs.yaml` |

---

## Still can't find it?

1. Check `INTEGRATION_SNIPPETS.md` — a compact copy-paste cookbook
   of the minimal `integrations:` block for every backend type.
2. Check `../GettingStarted.md` — the plain-language decision tree
   and the request form you can hand to a developer directly.
3. Check `../api-schema.json` combined with your editor's YAML
   extension — it'll autocomplete and flag errors as you type if
   you keep the `# yaml-language-server:` line at the top of your
   file.
4. Still stuck? Run `python3 scripts/validate_apis.py
   apigatewayconfig/apis` against whatever you've written so far —
   the error message names the exact missing/wrong field.
