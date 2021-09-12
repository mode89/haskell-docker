FROM ubuntu:20.04

ARG CONTAINER_USER
ARG HOST_USER_GID
ARG HOST_USER_UID
ARG TIMEZONE

WORKDIR /tmp/workdir

# Disable interactive configuration
ENV DEBIAN_FRONTEND=noninteractive

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

############################################################################
# Install Cabal and GHC
############################################################################

RUN apt-get install -y \
        build-essential \
        curl
RUN curl -OL https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup
RUN chmod 755 x86_64-linux-ghcup
ENV GHCUP_INSTALL_BASE_PREFIX /opt/ghcup
RUN ./x86_64-linux-ghcup install cabal 3.6.0.0
RUN ./x86_64-linux-ghcup install ghc 8.10.7
RUN rm x86_64-linux-ghcup
ENV PATH ${PATH}:${GHCUP_INSTALL_BASE_PREFIX}/.ghcup/bin
ENV PATH ${PATH}:${GHCUP_INSTALL_BASE_PREFIX}/.ghcup/ghc/8.10.7/bin

############################################################################
# Install GHCJS
############################################################################

RUN apt-get install -y git
RUN apt-get install -y libgmp-dev

ENV CABAL_DIR /tmp/workdir/.cabal
RUN cabal update
RUN cabal install alex
RUN cabal install happy-1.19.12

RUN apt-get install -y python3
RUN apt-get install -y autoconf
RUN apt-get install -y libtinfo-dev

WORKDIR /opt/emsdk
RUN git clone https://github.com/emscripten-core/emsdk.git .
RUN git checkout b362b173261bcf2f5e5318702398a0871b37a0c4
RUN ./emsdk install latest
RUN ./emsdk activate latest

WORKDIR /tmp/workdir/ghcjs
RUN git clone https://github.com/ghcjs/ghcjs.git .
RUN git checkout 8802b310c89eda51f0b1ac0cded74a756642a615
RUN git submodule update --init --recursive --jobs 8

COPY revert-e4cd4232.patch .
RUN patch -p1 -i revert-e4cd4232.patch
COPY boot-no-parallel-build.patch .
RUN patch -p1 -i boot-no-parallel-build.patch
COPY ghc-boot ghc/libraries/ghc-boot/dist-install/build
COPY configure-libraries.sh .
RUN ./configure-libraries.sh

RUN utils/makePackages.sh

ENV GHCJS_DIR /opt/ghcjs
RUN mkdir -p ${GHCJS_DIR:?}/bin
RUN cabal v2-install \
        --overwrite-policy=always \
        --install-method=copy \
        --installdir=${GHCJS_DIR:?}/bin

RUN mkdir -p ${GHCJS_DIR:?}/doc
RUN /bin/bash -c " \
        source /opt/emsdk/emsdk_env.sh && \
        ${GHCJS_DIR:?}/bin/ghcjs-boot --source-dir lib/boot"

USER user
ENV CABAL_DIR /home/user/.cabal
WORKDIR /home/user
RUN cabal update
RUN cabal install happy

WORKDIR /workdir
CMD /bin/bash
