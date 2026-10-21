# syntax=docker/dockerfile:1
#
# The kit in a container, for people who would rather not install anything.
#
#   docker build -f docker/Dockerfile -t ci-kit .
#   docker run --rm -v "$PWD:/work" -v /var/run/docker.sock:/var/run/docker.sock ci-kit gate
#
# The Docker client is here so the container can drive the host's daemon: the
# services and act both need it.

FROM node:22-bookworm-slim AS node

FROM debian:bookworm-slim

ARG TARGETARCH
ARG DOCKER_VERSION=27.3.1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git make coreutils \
 && rm -rf /var/lib/apt/lists/*

# Node from the official image, so the version matches what most projects use.
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# The Docker client, so the kit can drive the host's daemon.
RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
      amd64) arch=x86_64 ;; \
      arm64) arch=aarch64 ;; \
      *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://download.docker.com/linux/static/stable/${arch}/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz; \
    tar -xzf /tmp/docker.tgz -C /tmp; \
    install -m 0755 /tmp/docker/docker /usr/local/bin/docker; \
    rm -rf /tmp/docker /tmp/docker.tgz

COPY . /opt/ci-kit
RUN ln -s /opt/ci-kit /usr/local/share/ci-kit \
 && ln -s /opt/ci-kit/bin/ci /usr/local/bin/ci \
 && chmod +x /opt/ci-kit/bin/ci /opt/ci-kit/bin/install.sh

WORKDIR /work
ENTRYPOINT ["ci"]
CMD ["gate"]
