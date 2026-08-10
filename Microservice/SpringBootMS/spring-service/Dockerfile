# ==========================================================
# STAGE 1: Build
# ==========================================================

FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy pom.xml first for dependency caching
COPY pom.xml .

RUN mvn dependency:go-offline

# Copy source code
COPY src ./src

# Build application
RUN mvn package -DskipTests


# ==========================================================
# STAGE 2: Runtime
# ==========================================================

FROM eclipse-temurin:17-jre

WORKDIR /app

# Create non-root user
RUN groupadd --system spring && \
    useradd --system --gid spring spring

# Create application log directory
RUN mkdir -p /app/logs && \
    chown -R spring:spring /app

# Copy application JAR
COPY --from=builder /app/target/*.jar app.jar

# Copy OpenTelemetry Agent
COPY opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar

# Make sure application files are accessible by non-root user
RUN chown spring:spring /app/app.jar \
    /otel/opentelemetry-javaagent.jar

# Application port
EXPOSE 8080

# JVM options
ENV JAVA_OPTS=""

# OpenTelemetry configuration
ENV OTEL_SERVICE_NAME=spring-service
ENV OTEL_TRACES_EXPORTER=otlp
ENV OTEL_METRICS_EXPORTER=none
ENV OTEL_LOGS_EXPORTER=none
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger.ns-tracing.svc.cluster.local:4318

# Run as non-root
USER spring

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS \
-javaagent:/otel/opentelemetry-javaagent.jar \
-Dotel.service.name=$OTEL_SERVICE_NAME \
-Dotel.traces.exporter=$OTEL_TRACES_EXPORTER \
-Dotel.metrics.exporter=$OTEL_METRICS_EXPORTER \
-Dotel.logs.exporter=$OTEL_LOGS_EXPORTER \
-Dotel.exporter.otlp.endpoint=$OTEL_EXPORTER_OTLP_ENDPOINT \
-jar app.jar"]
