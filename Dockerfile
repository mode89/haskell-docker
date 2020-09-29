FROM haskell:8.10.2

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

RUN apt-get install -y \
        libgtk-3-dev

USER user
RUN ln -s /workdir/.stack-global /home/user/.stack

WORKDIR /workdir
CMD /bin/bash
