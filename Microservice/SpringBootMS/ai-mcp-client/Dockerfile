# ==========================================================
# STAGE 1: BUILD
# ==========================================================

FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy Maven descriptor first for dependency caching
COPY pom.xml .

RUN mvn dependency:go-offline

# Copy application source
COPY src ./src

# Build Spring Boot application
RUN mvn clean package -DskipTests


# ==========================================================
# STAGE 2: RUNTIME
# ==========================================================

FROM eclipse-temurin:17-jre

WORKDIR /app

# Create non-root user
RUN groupadd --system spring && \
    useradd --system --gid spring spring

# Copy Spring Boot JAR
COPY --from=builder /app/target/*.jar app.jar

# Give application user ownership
RUN chown spring:spring /app/app.jar

# Run as non-root
USER spring


# ==========================================================
# APPLICATION
# ==========================================================

EXPOSE 8081

# JVM options can be supplied at runtime
ENV JAVA_OPTS=""


# ==========================================================
# START APPLICATION
# ==========================================================

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
