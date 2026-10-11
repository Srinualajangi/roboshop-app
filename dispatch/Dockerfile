# syntax=docker/dockerfile:1
# RoboShop dispatch — Go AMQP consumer, no listening port. Upstream: golang:1.17 full image (~800 MB), root.
FROM golang:1.24 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/dispatch .

FROM gcr.io/distroless/static-debian12:nonroot
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.title="roboshop-dispatch" org.opencontainers.image.revision="${GIT_SHA}"
COPY --from=build /out/dispatch /dispatch
USER nonroot:nonroot
ENTRYPOINT ["/dispatch"]
