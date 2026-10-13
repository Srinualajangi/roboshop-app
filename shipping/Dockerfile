# syntax=docker/dockerfile:1
# RoboShop shipping — Spring Boot 2.3 / Java 8. Upstream: debian:10 + openjdk:8-jdk as root.

########## build stage: JDK + Maven (never shipped) ##########
FROM maven:3.9-eclipse-temurin-8@sha256:0f402712b7a469189cfea5ec69cdcadcb32b22aaf1ea62777ab925c3d8470175 AS build
WORKDIR /src
# 1) dependencies only — cached until pom.xml changes
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
# 2) source + package (skip tests here; CI runs them as a separate stage in Phase 6)
COPY src ./src
RUN mvn -B -q package -DskipTests && ls -l target/*.jar

########## runtime stage: JRE only ##########
FROM eclipse-temurin:8-jre@sha256:7806d0570e7234dccae4232e8273e87a0fcb74ca7c6f8692c9f5c672f355fd1d
ARG GIT_SHA=unknown
ARG VERSION=0.0.0-dev
LABEL org.opencontainers.image.title="roboshop-shipping" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0"

RUN groupadd --system --gid 10001 app && useradd --system --uid 10001 --gid app --no-create-home app
WORKDIR /opt/shipping
COPY --from=build /src/target/shipping-1.0.jar app.jar

ENV CART_ENDPOINT=cart:8080 \
    DB_HOST=mysql \
    JAVA_OPTS="-Xms256m -Xmx512m -XX:+ExitOnOutOfMemoryError"
USER 10001:10001
EXPOSE 8080
# no curl in this image: use bash's /dev/tcp to send a tiny HTTP request
HEALTHCHECK --interval=15s --timeout=5s --start-period=90s --retries=3 \
  CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/8080 && printf 'GET /health HTTP/1.0\\r\\n\\r\\n' >&3 && head -1 <&3 | grep -q ' 200 '"]
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /opt/shipping/app.jar"]
