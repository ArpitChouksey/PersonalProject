#!/usr/bin/env python3
"""
validate_apis.py

Validates every YAML file under apigatewayconfig/apis/ before Terraform
runs. Two layers of checks:

  1. Structural  — mirrors apigatewayconfig/schema/api-schema.json
                    (required fields, enums, path/ARN patterns,
                    conditional per-integration-type config).

  2. Relational   — checks JSON Schema cannot express on its own:
                       - duplicate api.name across files
                       - duplicate routes within a file
                       - route.integration references a real integration
                       - route.authorization references a real authorizer
                       - domain / lambda / ALB / NLB required fields present

Only depends on PyYAML, so it runs in any CI image without extra
installs.

Usage:
    python3 validate_apis.py [path-to-apis-dir]

Exit code 0  = all files valid
Exit code 1  = one or more files failed validation
"""

import sys
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is required. Install with: pip install pyyaml")
    sys.exit(2)


VALID_PROTOCOL_TYPES = {"HTTP", "REST", "WEBSOCKET"}

# AWS's actual supported quick-create integration_subtype values for
# HTTP/WebSocket APIs. Notably: NO S3 operations are supported this
# way -- there is no direct HTTP-API-to-S3 integration without a
# Lambda in front. S3 access via API Gateway without Lambda is only
# possible on REST APIs, via the non-proxy AWS integration type with
# a raw `uri` + VTL mapping (config.uri, not integration_subtype).
VALID_AWS_INTEGRATION_SUBTYPES = {
    "SQS-SendMessage", "SQS-ReceiveMessage", "SQS-DeleteMessage", "SQS-PurgeQueue",
    "EventBridge-PutEvents",
    "AppConfig-GetConfiguration",
    "Kinesis-PutRecord",
    "StepFunctions-StartExecution", "StepFunctions-StartSyncExecution", "StepFunctions-StopExecution",
}
VALID_ENDPOINT_TYPES = {"REGIONAL", "EDGE", "PRIVATE"}
VALID_METHODS = {"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD", "ANY"}
VALID_INTEGRATION_TYPES = {"LAMBDA", "ALB", "NLB", "HTTP", "AWS"}
VALID_LOGGING_LEVELS = {"OFF", "ERROR", "INFO"}
VALID_AUTHORIZER_TYPES = {"TOKEN", "REQUEST", "COGNITO_USER_POOLS", "JWT"}
RESERVED_AUTHORIZATIONS = {"NONE", "AWS_IAM"}

ARN_LAMBDA = re.compile(r"^arn:aws:lambda:")
ARN_ALB = re.compile(r"^arn:aws:elasticloadbalancing:")
ARN_ACM = re.compile(r"^arn:aws:acm:")
ARN_APIGW = re.compile(r"^arn:aws:apigateway:")
URL_HTTP = re.compile(r"^https?://")
PATH_LEADING_SLASH = re.compile(r"^/")
API_NAME_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")


class ValidationError:
    def __init__(self, file, message):
        self.file = file
        self.message = message

    def __str__(self):
        return f"  \u2717 {self.message}"


class Validator:
    def __init__(self):
        self.errors = []
        self.seen_api_names = {}  # api_name -> file that first declared it

    def fail(self, file, message):
        self.errors.append(ValidationError(file, message))

    # -----------------------------------------------------------------
    # Structural checks (one file at a time)
    # -----------------------------------------------------------------

    def validate_file(self, path, doc):
        file = path.name

        if not isinstance(doc, dict):
            self.fail(file, "Top-level YAML must be a mapping.")
            return None

        import_block = doc.get("import") or {}
        using_import = bool(import_block.get("enabled"))

        required_keys = ["enabled", "api"] if using_import else ["enabled", "api", "routes", "integrations"]
        for required in required_keys:
            if required not in doc:
                self.fail(file, f"Missing required top-level key: '{required}'")

        if using_import:
            openapi_file = import_block.get("openapi_file")
            if not openapi_file:
                self.fail(file, "import.enabled is true but import.openapi_file is missing")
            else:
                # Walk upward looking for the apigatewayconfig root
                # (identified by its "schema" subdirectory) rather
                # than assuming a fixed directory depth -- this
                # folder gets scanned from apis/, examples/*/, and
                # testing/ alike, at different nesting levels.
                candidate = None
                current = path.parent
                for _ in range(6):
                    if (current / "schema").is_dir():
                        candidate = current / "openapi" / openapi_file
                        break
                    if current.parent == current:
                        break
                    current = current.parent
                if candidate is None:
                    candidate = path.parent.parent / "openapi" / openapi_file
                if not candidate.exists():
                    self.fail(
                        file,
                        f"import.openapi_file '{openapi_file}' not found at expected location "
                        f"'{candidate}' -- adjust if your openapi/ directory lives elsewhere",
                    )

        api = doc.get("api", {}) or {}
        protocol_type = api.get("protocol_type")

        # api.name
        name = api.get("name")
        if not name:
            self.fail(file, "api.name is required")
        elif not API_NAME_PATTERN.match(str(name)):
            self.fail(file, f"api.name '{name}' must be lowercase, hyphenated (e.g. 'employee-api')")

        # api.protocol_type
        if protocol_type not in VALID_PROTOCOL_TYPES:
            self.fail(
                file,
                f"api.protocol_type must be one of {sorted(VALID_PROTOCOL_TYPES)}, got '{protocol_type}'",
            )

        # endpoint.type
        endpoint_type = (doc.get("endpoint") or {}).get("type")
        if endpoint_type is not None and endpoint_type not in VALID_ENDPOINT_TYPES:
            self.fail(
                file,
                f"endpoint.type must be one of {sorted(VALID_ENDPOINT_TYPES)}, got '{endpoint_type}'",
            )

        # logging.logging_level
        logging_level = (doc.get("logging") or {}).get("logging_level")
        if logging_level is not None and logging_level not in VALID_LOGGING_LEVELS:
            self.fail(
                file,
                f"logging.logging_level must be one of {sorted(VALID_LOGGING_LEVELS)}, got '{logging_level}'",
            )

        # domain
        domain = doc.get("domain") or {}
        if domain.get("enabled"):
            for field in ("name", "certificate_arn", "base_path"):
                if not domain.get(field):
                    self.fail(file, f"domain.enabled is true but domain.{field} is missing")
            cert = domain.get("certificate_arn")
            if cert and not ARN_ACM.match(cert):
                self.fail(file, f"domain.certificate_arn does not look like an ACM ARN: '{cert}'")

        # security.waf -- NOTE: this is the only WAF field the module
        # actually reads (aws_wafv2_web_acl_association in security.tf).
        # A top-level `waf:` block is not wired to anything.
        waf = (doc.get("security") or {}).get("waf") or {}
        if waf.get("enabled") and not waf.get("web_acl_arn"):
            self.fail(file, "security.waf.enabled is true but security.waf.web_acl_arn is missing")

        # integrations
        integration_names = set()
        integrations = doc.get("integrations") or []
        for idx, integration in enumerate(integrations):
            self._validate_integration(file, idx, integration, integration_names, protocol_type)

        # authorizers
        authorizer_names = set()
        authorizers = doc.get("authorizers") or []
        for idx, authorizer in enumerate(authorizers):
            self._validate_authorizer(file, idx, authorizer, authorizer_names)

        # routes
        routes = doc.get("routes") or []
        self._validate_routes(file, protocol_type, routes, integration_names, authorizer_names)

        return name

    def _validate_integration(self, file, idx, integration, seen_names, protocol_type):
        label = f"integrations[{idx}]"
        name = integration.get("name")
        itype = integration.get("type")
        config = integration.get("config") or {}

        if not name:
            self.fail(file, f"{label}.name is required")
        else:
            if name in seen_names:
                self.fail(file, f"Duplicate integration name: '{name}'")
            seen_names.add(name)
            label = f"integration '{name}'"

        if itype not in VALID_INTEGRATION_TYPES:
            self.fail(
                file,
                f"{label}.type must be one of {sorted(VALID_INTEGRATION_TYPES)}, got '{itype}'",
            )
            return

        if itype == "LAMBDA":
            arn = config.get("function_arn")
            if not arn:
                self.fail(file, f"{label} (type LAMBDA) requires config.function_arn")
            elif not ARN_LAMBDA.match(arn):
                self.fail(file, f"{label}.config.function_arn does not look like a Lambda ARN: '{arn}'")

        elif itype in ("ALB", "NLB"):
            listener = config.get("listener_arn")
            vpc_link = config.get("vpc_link_id")
            if not listener:
                self.fail(file, f"{label} (type {itype}) requires config.listener_arn")
            elif not ARN_ALB.match(listener):
                self.fail(file, f"{label}.config.listener_arn does not look like a load balancer ARN: '{listener}'")
            if not vpc_link:
                self.fail(file, f"{label} (type {itype}) requires config.vpc_link_id")

        elif itype == "HTTP":
            url = config.get("url")
            if not url:
                self.fail(file, f"{label} (type HTTP) requires config.url")
            elif not URL_HTTP.match(url):
                self.fail(file, f"{label}.config.url must start with http:// or https://: '{url}'")

        elif itype == "AWS":
            if protocol_type == "REST":
                uri = config.get("uri")
                if not uri:
                    self.fail(
                        file,
                        f"{label} (type AWS, REST API) requires config.uri "
                        f"(e.g. arn:aws:apigateway:{{region}}:sqs:path/{{account_id}}/{{queue}}) "
                        f"— REST API v1 does not support the v2 'integration_subtype' shorthand",
                    )
                elif not ARN_APIGW.match(uri):
                    self.fail(file, f"{label}.config.uri does not look like an apigateway service ARN: '{uri}'")
            else:
                # HTTP / WEBSOCKET use the v2 quick-create shorthand
                subtype = config.get("integration_subtype")
                if not subtype:
                    self.fail(file, f"{label} (type AWS, {protocol_type} API) requires config.integration_subtype")
                elif subtype not in VALID_AWS_INTEGRATION_SUBTYPES:
                    self.fail(
                        file,
                        f"{label}.config.integration_subtype '{subtype}' is not a subtype AWS supports for "
                        f"{protocol_type} APIs (supported: {', '.join(sorted(VALID_AWS_INTEGRATION_SUBTYPES))}). "
                        f"Notably S3 is not supported this way -- use a Lambda in front, or a REST API's "
                        f"non-proxy AWS integration with a raw config.uri instead.",
                    )
                if not config.get("credentials_arn"):
                    self.fail(file, f"{label} (type AWS, {protocol_type} API) requires config.credentials_arn")

    def _validate_authorizer(self, file, idx, authorizer, seen_names):
        label = f"authorizers[{idx}]"
        name = authorizer.get("name")
        atype = authorizer.get("type")

        if not name:
            self.fail(file, f"{label}.name is required")
        else:
            if name in seen_names:
                self.fail(file, f"Duplicate authorizer name: '{name}'")
            seen_names.add(name)
            label = f"authorizer '{name}'"

        if atype not in VALID_AUTHORIZER_TYPES:
            self.fail(
                file,
                f"{label}.type must be one of {sorted(VALID_AUTHORIZER_TYPES)}, got '{atype}'",
            )
            return

        if atype in ("TOKEN", "REQUEST") and not authorizer.get("authorizer_uri"):
            self.fail(file, f"{label} (type {atype}) requires authorizer_uri")

        if atype == "COGNITO_USER_POOLS" and not authorizer.get("provider_arns"):
            self.fail(file, f"{label} (type COGNITO_USER_POOLS) requires provider_arns")

        if atype == "JWT" and not authorizer.get("jwt_configuration"):
            self.fail(file, f"{label} (type JWT) requires jwt_configuration")

    def _validate_routes(self, file, protocol_type, routes, integration_names, authorizer_names):
        seen_route_keys = set()

        for idx, route in enumerate(routes):
            label = f"routes[{idx}]"

            if protocol_type == "WEBSOCKET":
                route_key = route.get("route_key")
                if not route_key:
                    self.fail(file, f"{label}.route_key is required for WEBSOCKET routes")
                else:
                    label = f"route '{route_key}'"
                    if route_key in seen_route_keys:
                        self.fail(file, f"Duplicate route: '{route_key}'")
                    seen_route_keys.add(route_key)
            else:
                path = route.get("path")
                method = route.get("method")

                if not path:
                    self.fail(file, f"{label}.path is required")
                elif not PATH_LEADING_SLASH.match(path):
                    self.fail(file, f"{label}.path must start with '/': got '{path}'")

                if method not in VALID_METHODS:
                    self.fail(
                        file,
                        f"{label}.method must be one of {sorted(VALID_METHODS)}, got '{method}'",
                    )

                if path and method:
                    dedupe_key = f"{method} {path}"
                    label = f"route '{dedupe_key}'"
                    if dedupe_key in seen_route_keys:
                        self.fail(file, f"Duplicate route: '{dedupe_key}'")
                    seen_route_keys.add(dedupe_key)

            # integration reference
            integration = route.get("integration")
            if not integration:
                self.fail(file, f"{label}.integration is required")
            elif integration not in integration_names:
                self.fail(
                    file,
                    f"{label} references integration '{integration}', which is not defined in integrations[]",
                )

            # authorizer reference
            authorization = route.get("authorization")
            if authorization and authorization not in RESERVED_AUTHORIZATIONS:
                if authorization not in authorizer_names:
                    self.fail(
                        file,
                        f"{label} references authorization '{authorization}', which is not NONE/AWS_IAM "
                        f"and is not defined in authorizers[]",
                    )

    # -----------------------------------------------------------------
    # Cross-file check
    # -----------------------------------------------------------------

    def register_api_name(self, name, file):
        if name is None:
            return
        if name in self.seen_api_names:
            first_file = self.seen_api_names[name]
            self.fail(file, f"Duplicate api.name '{name}' — already declared in {first_file}")
        else:
            self.seen_api_names[name] = file


def load_yaml(path):
    with open(path, "r") as f:
        return yaml.safe_load(f)


def main():
    apis_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("apigatewayconfig/apis")

    if not apis_dir.is_dir():
        print(f"ERROR: '{apis_dir}' is not a directory")
        sys.exit(2)

    yaml_files = sorted(apis_dir.glob("*.yaml")) + sorted(apis_dir.glob("*.yml"))

    if not yaml_files:
        print(f"No YAML files found in {apis_dir} — nothing to validate.")
        sys.exit(0)

    validator = Validator()
    per_file_errors = {}

    for path in yaml_files:
        try:
            doc = load_yaml(path)
        except yaml.YAMLError as e:
            validator.fail(path.name, f"Invalid YAML syntax: {e}")
            per_file_errors[path.name] = validator.errors[-1:]
            continue

        before = len(validator.errors)
        name = validator.validate_file(path, doc)
        validator.register_api_name(name, path.name)
        after = len(validator.errors)

        per_file_errors[path.name] = validator.errors[before:after]

    print(f"Validated {len(yaml_files)} file(s) in {apis_dir}\n")

    failed = False
    for filename, errs in per_file_errors.items():
        if errs:
            failed = True
            print(f"{filename}")
            for e in errs:
                print(str(e))
            print()
        else:
            print(f"  \u2713 {filename}")

    if failed:
        print(f"\nFAILED — {sum(len(v) for v in per_file_errors.values())} error(s) found.")
        sys.exit(1)
    else:
        print("\nAll files valid.")
        sys.exit(0)


if __name__ == "__main__":
    main()
