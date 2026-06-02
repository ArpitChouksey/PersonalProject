from opentelemetry import trace

from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider

from opentelemetry.sdk.trace.export import (
    BatchSpanProcessor
)

from opentelemetry.exporter.otlp.proto.http.trace_exporter import (
    OTLPSpanExporter
)

import os

resource = Resource.create({
    "service.name": "python-service"
})

provider = TracerProvider(resource=resource)

otlp_endpoint = os.getenv(
    "OTEL_EXPORTER_OTLP_ENDPOINT",
    "http://localhost:4318/v1/traces"
)

otlp_exporter = OTLPSpanExporter(
    endpoint=otlp_endpoint
)

provider.add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

trace.set_tracer_provider(provider)

print(f"OTEL Endpoint: {otlp_endpoint}")
print("OpenTelemetry Trace Provider Initialized")
