FROM ubuntu:trusty
MAINTAINER ek <417@xmlad.com>

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
RUN apt-mark hold initscripts udev plymouth mountall
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends \
        openssh-server sudo vim \
        net-tools \
        lxde x11vnc xvfb \
        gtk2-engines-murrine ttf-ubuntu-font-family ttf-wqy-zenhei \
        libreoffice firefox \
	lxdm \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/bin/python3 /usr/bin/python

ADD noVNC /noVNC/
ADD run.sh /
EXPOSE 6080
EXPOSE 6001
EXPOSE 5900
EXPOSE 22
WORKDIR /
ENTRYPOINT ["/run.sh"]
