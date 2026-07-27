# Getting Started (No Tech Background Required)

This guide assumes you have never used Terraform, AWS, or "API
Gateway" before. If you can fill out a web form, you can create
one of these files.

---

## First, three words you'll see everywhere

**API** — think of it as a phone number for a piece of software.
Instead of a person calling a business, one computer program calls
another. "Creating an API" means giving that phone number to the
outside world so people can call in.

**Lambda** — a small, self-contained piece of code that runs only
when it's called, then stops. Think of it as a vending machine: it
sits idle, and only "does something" the moment someone presses a
button (makes a request).

**Route** — the specific address someone dials, like an extension
number. `/orders` and `/orders/{id}` are two different routes on
the same API — like "press 1 for sales, press 2 for support."

That's genuinely most of the vocabulary you need. Everything else
in this guide builds on those three ideas.

---

## The one-page mental model

```
Someone on the internet
        |
        v
   Your API  (the phone number)
        |
        v
     A Route  (the extension they dialed)
        |
        v
  An Integration  (who actually answers -- a Lambda? a website?
                    a service running on a server somewhere?)
```

A configuration file is just answering three questions:
**what's the phone number, what extensions exist, and who answers
each one.**

---

## Step 1 — Answer 3 questions

Ask whoever wants this API (or ask yourself, if it's your own
project):

**Question 1: "What kind of API is this?"**

| They say something like... | You write |
|---|---|
| "just a normal API", "basic CRUD", "nothing fancy" | `HTTP` |
| "we need API keys for partners", "usage limits", "quotas" | `REST` |
| "real-time chat", "live updates", "stays connected" | `WEBSOCKET` |

Not sure? Write `HTTP`. It's the simplest option and covers almost
every situation. You can always change it later.

**Question 2: "What answers the phone when a request comes in?"**

| They say... | You write | You'll also need... |
|---|---|---|
| "a Lambda function" | `LAMBDA` | the function's ID (called an ARN) |
| "something running in Kubernetes / EKS" | `NLB` | a load balancer address + a network link |
| "something running in ECS / ECS Fargate" | `ALB` | a load balancer address + a network link |
| "a server / EC2 machine" | `ALB` | a load balancer address + a network link |
| "another website or external service" | `HTTP` | its web address (URL) |
| "just send it to a queue/notification service, no code needed" | `AWS` | which AWS service + a permission slip (IAM role) |

If you don't know which of these applies, ask "does this run as a
Lambda function, or is it a full server/website?" — that alone
usually tells you `LAMBDA` vs. everything else.

**Question 3: "What addresses (routes) does it need?"**

Just a plain list, e.g.:
```
See all orders     ->  GET  /orders
See one order      ->  GET  /orders/{id}
Create an order    ->  POST /orders
```
`{id}` means "a placeholder that changes" — like "order number 42"
instead of a fixed word.

That's it. Every other setting in this system (security, domains,
logging, firewalls) is optional and has safe defaults — you can
leave every one of them out and still get a working API.

---

## Step 2 — Start from the closest example

Don't write a file from a blank page. Copy the one that's closest
to your situation from `apigatewayconfig/examples/`:

| Your situation | Copy this file |
|---|---|
| A Lambda function, simple API | `01-api-types/example1_HTTP_API.yaml` |
| A Lambda function, need API keys/usage limits | `01-api-types/example2_REST_API.yaml` |
| Real-time / chat | `01-api-types/example3_WEBSOCKET_API.yaml` |
| Something running on Kubernetes (EKS) | `02-backend-integrations/example3_NLB.yaml` |
| ANY other scenario at all | Start at `INDEX.md` — a full scenario-to-file lookup table |
| Anything else | Look up your integration type in `INTEGRATION_SNIPPETS.md` |

---

## Step 3 — Fill in the blanks

Here is the entire shape of a minimal file, in plain terms:

```yaml
enabled: true                     # is this API turned on? almost always "true"

api:
  name: <give it a short, unique nickname>     # e.g. "order-service"
  protocol_type: <HTTP, REST, or WEBSOCKET>      # from Question 1

integrations:
  - name: <a label you make up>       # e.g. "order-backend"
    type: <LAMBDA, ALB, NLB, HTTP, or AWS>     # from Question 2
    config:
      # fill in only the ONE line that matches your type above:
      function_arn: <Lambda's ID>              # if type: LAMBDA
      listener_arn: <load balancer address>     # if type: ALB or NLB
      vpc_link_id:  <network link ID>           # if type: ALB or NLB
      url: <https://the-other-website.com>      # if type: HTTP

routes:
  - path: <the address, e.g. /orders>      # from Question 3
    method: <GET, POST, PUT, or DELETE>
    integration: <the label you made up above>   # must match exactly
```

Save it inside `apigatewayconfig/apis/`, name the file anything
you like (the `.yaml` ending matters, the filename itself doesn't).

---

## Step 4 — Let the computer check your work

Before anyone deploys anything, run this one command:

```bash
python3 scripts/validate_apis.py apigatewayconfig/apis
```

- If it says `All files valid.` — you're done. Hand it off, or
  deploy it yourself if that's your role.
- If it shows a red `✗` — it tells you exactly what's wrong, in
  plain English, e.g. *"route references integration 'foo', which
  is not defined"* means you typo'd the label somewhere. Fix that
  one line and run the command again.

You never need to guess whether you did it right — the checker
tells you.

---

## A real, worked example

**What someone told me:**
> "We have an order-service running in Kubernetes, behind an
> internal load balancer. We just need to be able to look up an
> order by ID, or list all of them. No login required for now,
> it's internal only."

**What I translate that into:**

| Their words | My answer |
|---|---|
| "Kubernetes" | Question 2 -> `NLB` |
| "look up an order by ID, list all of them" | Question 3 -> `GET /orders`, `GET /orders/{id}` |
| "no login required" | leave authorization out entirely |

**The two pieces of information I go get** (from whoever manages
that load balancer, or the AWS console):
1. The load balancer's listener address (an ARN)
2. A "VPC Link" ID — this is just a pre-approved network tunnel
   between the API and internal AWS resources. If one already
   exists for this load balancer, reuse it. If not, someone with
   AWS access creates one — a one-time thing, then everyone reuses
   it.

**The resulting file** — nine lines, no jargon left in it:

```yaml
enabled: true

api:
  name: order-service
  protocol_type: HTTP

integrations:
  - name: order-nlb
    type: NLB
    config:
      listener_arn: arn:aws:elasticloadbalancing:us-west-2:111111111111:listener/net/order-nlb/abc123
      vpc_link_id: vpclink-order-service-001

routes:
  - path: /orders
    method: GET
    integration: order-nlb

  - path: /orders/{id}
    method: GET
    integration: order-nlb
```

A copy of this exact file lives at `examples/02-backend-integrations/example3_NLB.yaml`.

---

## "I don't even understand what they're asking for"

That's fine — you don't have to be the one who figures it out.
Hand the person this form and just copy their answers into Step 3
above. You're a translator here, not a designer.

> **Plain-Language API Request Form**
>
> 1. What should we call this? _______________
> 2. Is this a normal service, or does it need login keys/usage
>    limits for outside partners? _______________
> 3. What actually handles the request? Choose one:
>    - A small piece of code (Lambda)
>    - Something running on Kubernetes
>    - Something running on a regular server or ECS
>    - Another website/service out on the internet
>    - Send straight to a queue or notification service
> 4. Depending on your answer to #3, what's the ID/address for
>    that thing? _______________
> 5. What are the specific web addresses (and actions — look up,
>    create, update, delete) you need? _______________
> 6. Does this need a login/token to use, or is it open (or
>    internal-only)? _______________

Every one of their answers maps directly onto Question 1, 2, or 3
above — nothing on this form requires either of you to know what
"Terraform" or "API Gateway" even is.

---

## If you get stuck

- **Validator says something you don't understand** — copy the
  exact error message and ask the platform team; it always points
  at one specific field.
- **You don't know the ARN/ID for something** — ask whoever set up
  that resource (Lambda, load balancer, etc.) in the AWS console;
  it's usually one copy-paste away from their screen.
- **Nothing here matches your situation** — check
  `INTEGRATION_SNIPPETS.md` for every supported backend type, or
  ask the platform team directly rather than guessing.
