# Debian 13 "trixie" + Temurin JDK 17 + Docker engine (for Docker-in-Docker).
#
# Everything is installed here rather than through dev container "features",
# because the editor used with this container does not support them.
FROM debian:trixie

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive

# Base packages: build prerequisites plus what the Gradle build and the Docker
# daemon need at runtime (iptables/iproute2 for container networking).
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg \
        git \
        openssh-client \
        sudo \
        locales \
        procps \
        less \
        unzip \
        zip \
        tar \
        xz-utils \
        iproute2 \
        iptables \
        uidmap \
        fuse-overlayfs \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ---------------------------------------------------------------------------
# JDKs: 21 and 25 from Debian, 17 from Adoptium.
#
# The upgrade plan targets Java 21, with 25 as a later step, so all three are
# installed side by side to allow building and testing against each.
#
# 21 and 25 come from trixie's own openjdk packages. 17 does not: Debian 13
# dropped openjdk-17 entirely (trixie carries 21 and 25 only), so it comes from
# the Adoptium apt repository, which does publish a trixie suite.
# ---------------------------------------------------------------------------
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        openjdk-21-jdk \
        openjdk-25-jdk \
    && rm -rf /var/lib/apt/lists/*

RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
        -o /etc/apt/keyrings/adoptium.asc \
    && chmod a+r /etc/apt/keyrings/adoptium.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb trixie main" \
        > /etc/apt/sources.list.d/adoptium.list \
    && apt-get update \
    && apt-get -y install --no-install-recommends temurin-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Per-version handles, so a build can select a JDK without hardcoding paths:
#   JAVA_HOME=$JAVA_HOME_21 ./gradlew ...
ENV JAVA_HOME_17=/usr/lib/jvm/temurin-17-jdk-amd64 \
    JAVA_HOME_21=/usr/lib/jvm/java-21-openjdk-amd64 \
    JAVA_HOME_25=/usr/lib/jvm/java-25-openjdk-amd64

# Default is 17, and must stay 17 until Gradle is upgraded. The wrapper is pinned
# to Gradle 7.6.4, which supports Java 8-19 only: on 21 it fails outright with
# "Unsupported class file major version 65". Move the default to 21 as part of
# the Gradle 8.14.3+ step (upgrade plan, Phase 2).
#
# Installing 21 and 25 anyway is still useful - Gradle auto-detects JDKs under
# /usr/lib/jvm for toolchains, and it allows verifying --release behaviour and
# runtime compatibility against the versions the plan targets.
ENV JAVA_HOME=${JAVA_HOME_17}
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# apt registers alternatives for all three and would otherwise leave the newest
# as the system default; pin /usr/bin/java and /usr/bin/javac to match JAVA_HOME.
RUN update-alternatives --set java  ${JAVA_HOME_17}/bin/java \
    && update-alternatives --set javac ${JAVA_HOME_17}/bin/javac

# ---------------------------------------------------------------------------
# Docker engine, for Docker-in-Docker.
#
# The daemon is not started here; there is no init system in the container, so
# it is launched by the postStartCommand in devcontainer.json. The container
# must run privileged for that to work.
# ---------------------------------------------------------------------------
RUN curl -fsSL https://download.docker.com/linux/debian/gpg \
        -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian trixie stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get -y install --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Non-root user, in the docker group so it can talk to the daemon socket.
# ---------------------------------------------------------------------------
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && usermod -aG docker $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
