FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=container
ENV HOME=/home/container
ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080
ENV RESOLUTION=1280x720
ENV TZ=UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tini \
    supervisor \
    dbus \
    dbus-x11 \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    xterm \
    x11-xserver-utils \
    x11-utils \
    xfonts-base \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-scalable \
    xfonts-cyrillic \
    firefox \
    wget \
    curl \
    git \
    sudo \
    unzip \
    zip \
    vim \
    nano \
    net-tools \
    procps \
    htop \
    ca-certificates \
    openssl \
    locales \
    tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN useradd -m -d /home/container -s /bin/bash container && \
    echo "container ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p \
    /home/container/.vnc \
    /var/log/supervisor \
    /etc/supervisor/conf.d \
    /run/dbus

COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY xstartup /home/container/.vnc/xstartup

RUN chmod +x /entrypoint.sh && \
    chmod +x /home/container/.vnc/xstartup && \
    chown -R container:container /home/container

WORKDIR /home/container

EXPOSE 5901
EXPOSE 6080

ENTRYPOINT ["/usr/bin/tini","--"]

CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
