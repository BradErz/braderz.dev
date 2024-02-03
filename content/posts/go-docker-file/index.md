---
title: "Dockerfile for go microservices"
description: "Dockerfile for go microservices with buildkit caching"
summary: "Dockerfile for go microservices with buildkit caching"
date: 2024-02-03T12:17:34Z
tags:
- docker
draft: false
---

I've started using a new standard `Dockerfile` for all my projects which works really well for my usecase.

## Features

- secure, minimal courtsey of  using [distroless][distroless] base image
- fast using buildkit caching functionality to preserve cache accross builds. [docker build cache][docker build cache]

```Dockerfile
# we can have dependabot automatically updating this go version
FROM golang:1.21.6-alpine AS deps

WORKDIR /app

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg \
    go mod download

FROM golang:1.21.6-alpine AS build

ARG TARGETOS TARGETARCH
# We set a default value here but it can be customized with 
# --build-arg PROJECT=./cmd/myotherapp
ARG PROJECT=./cmd/myapp

WORKDIR /app

ENV CGO_ENABLED=0

# Mount a directory for go-build cache and the go mod cache.
# This is shareable accross builds
RUN --mount=target=. \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg \
    # the /out directory is important, you cant write to the current directory
    # because --mount=target=. is a read only mount
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /out/server ${PROJECT}

# This is the final image which will produce an artifact containing our single go binary.
FROM gcr.io/distroless/static-debian12:nonroot AS runner

COPY --from=build /out/server /server
USER 65534

CMD ["/server"]
```

If you want the same thing as above without all the comments you can find it in a public [gist][dockerfile gist]

You can also combine this image e.g. if you want to use insside a docker compose file:

```yaml
version: "3.8"

services:
  myapp:
    build:
      target: runner
      context: ./
      args:
        PROJECT: ./cmd/myapp
    volumes:
      - go-modules:/go/pkg/mod
    networks:
      - myapp-net

networks:
  myapp-net:
    driver: bridge

volumes:
  go-modules:

```

## Automatic go upgrades with dependabot

If you create a file `.github/dependabot.yml` dependabot will automatically update your go version inside your `Dockerfile`. We can also get dependabot to upgrade our `go.mod` dependencies aswell!

```yaml
---
version: 2
updates:
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"      
```

You can read more about [depenadbot in the docs][depenadbot docs] in the docs

## References

- [docker.com: Faster Multi-Platform Builds: Dockerfile Cross-Compilation Guide][docker blog]

<!-- Page Links -->
[distroless]: https://github.com/GoogleContainerTools/distroless "Distroless Images"
[docker blog]: https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/ "Docker blog"
[docker build cache]: https://docs.docker.com/build/cache/ "Docker build cache"
[dockerfile gist]: https://gist.github.com/BradErz/ea97696c5d6a84e43dd1ee785ceee827 "Dockerfile gist"
[depenadbot docs]: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#package-ecosystem "Dependabot docs"
