FROM ubuntu:20.04

ARG CONTAINER_USER
ARG HOST_USER_GID
ARG HOST_USER_UID
ARG TIMEZONE

WORKDIR /tmp

# Disable interactive configuration
ENV DEBIAN_FRONTEND=noninteractive

# Install host's certificates
ARG COPY_HOST_CERTIFICATES
COPY ca-certificates ca-certificates
RUN if [ ${COPY_HOST_CERTIFICATES} -eq 1 ]; then \
        cp -r ca-certificates /usr/local/share/ca-certificates && \
        apt-get update && \
        apt-get install -y ca-certificates && \
        update-ca-certificates; \
    fi

# Setup the host's timezone
RUN apt-get update && \
    ln -sf /usr/share/zoneinfo/${TIMEZONE:?} /etc/localtime && \
    apt-get install -y tzdata

# Create user
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

# *************************************************************************
# Install GHC and Cabal
# *************************************************************************

USER root
RUN apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:hvr/ghc && \
    apt-get install -y \
        cabal-install-2.4 \
        ghc-8.6.5
ENV PATH ${PATH}:/opt/cabal/2.4/bin:/opt/ghc/8.6.5/bin

# *************************************************************************
# Install GHCJS
# *************************************************************************

USER root
RUN apt-get update && \
    apt-get install -y \
        autoconf \
        git \
        libtinfo-dev \
        nodejs \
        npm \
        python3 \
        zlib1g-dev

USER user
RUN cabal update && \
    cabal install alex && \
    cabal install happy-1.19.9
ENV PATH ${PATH}:/home/user/.cabal/bin

USER root
ENV GHCJS_INSTALL_DIR /opt/ghcjs
RUN mkdir ${GHCJS_INSTALL_DIR:?} && \
    chown user:user ${GHCJS_INSTALL_DIR:?}

USER user
WORKDIR /tmp
ENV PATH ${PATH}:${GHCJS_INSTALL_DIR}/bin
RUN git clone --branch ghc-8.6 https://github.com/ghcjs/ghcjs.git && \
    cd ghcjs && \
    git submodule update --init --recursive && \
    sed --in-place \
        "s/^\(cabal.\+sandbox.\+init\)/\1 \${CABAL_SANDBOX_INIT_ARGS}/" \
        utils/makeSandbox.sh && \
    ./utils/makePackages.sh && \
    CABAL_SANDBOX_INIT_ARGS="--sandbox ${GHCJS_INSTALL_DIR}" \
        ./utils/makeSandbox.sh && \
    cabal install --jobs=$(nproc) && \
    cd /tmp && \
    rm -r /tmp/ghcjs && \
    ghcjs-boot

USER root
RUN chown -R root:root ${GHCJS_INSTALL_DIR:?}

# *************************************************************************
# Install webkit2gtk
# *************************************************************************

USER root
RUN apt-get update && \
    apt-get install -y \
        libgirepository1.0-dev \
        libwebkit2gtk-4.0-dev \
        pkg-config

# *************************************************************************
# Install stack
# *************************************************************************

USER root
RUN apt-get update && \
    apt-get install -y curl
RUN curl -sSL https://get.haskellstack.org/ | sh

USER user
RUN ln -s /workdir/.stack-global /home/user/.stack

WORKDIR /workdir
CMD /bin/bash
