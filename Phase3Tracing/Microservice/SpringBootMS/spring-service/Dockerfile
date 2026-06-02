# ---------- STAGE 1: Build ----------
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy pom.xml first for dependency caching
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source code
COPY src ./src

# Build application
RUN mvn clean package -DskipTests


# ---------- STAGE 2: Runtime ----------
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy jar from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Copy OpenTelemetry Agent
COPY opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar

# Expose application port
EXPOSE 8080

# Environment variables
ENV JAVA_OPTS=""

# Start application with OpenTelemetry
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS \
-javaagent:/otel/opentelemetry-javaagent.jar \
-Dotel.service.name=spring-service \
-Dotel.traces.exporter=otlp \
-Dotel.metrics.exporter=none \
-Dotel.logs.exporter=none \
-Dotel.exporter.otlp.endpoint=http://jaeger.ns-tracing.svc.cluster.local:4318 \
-jar app.jar"]
