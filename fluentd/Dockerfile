FROM fluentd@sha256:ea699c84b3a97e6d12f0bd15c3e09e1fb80635faee01d6a3b1c768c9d59a5532
USER root
RUN apk update && \
    apk add --virtual .build-dependencies build-base ruby-dev

RUN fluent-gem install fluent-plugin-elasticsearch && \
    fluent-gem install fluent-plugin-kubernetes_metadata_filter  && \
    fluent-gem install fluent-plugin-multi-format-parser

