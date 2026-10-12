# syntax=docker/dockerfile:1
# RoboShop dispatch — Go AMQP consumer, no listening port. Upstream: golang:1.17 full image (~800 MB), root.
FROM golang:1.24@sha256:d2d2bc1c84f7e60d7d2438a3836ae7d0c847f4888464e7ec9ba3a1339a1ee804 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/dispatch .

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.title="roboshop-dispatch" org.opencontainers.image.revision="${GIT_SHA}"
COPY --from=build /out/dispatch /dispatch
USER nonroot:nonroot
ENTRYPOINT ["/dispatch"]
