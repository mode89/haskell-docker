FROM ubuntu:20.04

ARG CONTAINER_USER
ARG HOST_USER_GID
ARG HOST_USER_UID
ARG TIMEZONE

WORKDIR /tmp

# Disable interactive configuration
ENV DEBIAN_FRONTEND=noninteractive

# Setup the host's timezone
RUN apt-get update && \
    ln -sf /usr/share/zoneinfo/${TIMEZONE:?} /etc/localtime && \
    apt-get install -y tzdata

############################################################################
# Install Cabal and GHC
############################################################################

ENV GHCUP_INSTALL_BASE_PREFIX /opt/ghcup
RUN apt-get install -y \
        build-essential \
        curl && \
    curl -OL https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup && \
    chmod 755 x86_64-linux-ghcup && \
    ./x86_64-linux-ghcup install cabal 3.6.0.0 && \
    ./x86_64-linux-ghcup install ghc 8.10.7 && \
    rm x86_64-linux-ghcup
ENV PATH ${PATH}:${GHCUP_INSTALL_BASE_PREFIX}/.ghcup/bin
ENV PATH ${PATH}:${GHCUP_INSTALL_BASE_PREFIX}/.ghcup/ghc/8.10.7/bin

############################################################################
# Install GHCJS
############################################################################

WORKDIR /tmp
COPY ghcjs ghcjs
RUN ghcjs/build
ENV PATH ${PATH}:/opt/ghcjs/bin

############################################################################
# Create user
############################################################################

RUN groupadd --gid ${HOST_USER_GID:?} ${CONTAINER_USER:?} && \
    useradd \
        --create-home \
        --shell /bin/bash \
        --uid ${HOST_USER_UID:?} \
        --gid ${CONTAINER_USER:?} \
        --groups 27 \
        ${CONTAINER_USER:?} && \
    echo "export PS1=\"(container) \$PS1\"" >> \
        /home/${CONTAINER_USER:?}/.bashrc && \
    echo "export PS1=\"(container) \$PS1\"" >> /root/.bashrc && \
    apt-get update && \
    apt-get install -y sudo && \
    echo "${CONTAINER_USER:?} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

############################################################################
# Finialize
############################################################################

WORKDIR /workdir
CMD /bin/bash
