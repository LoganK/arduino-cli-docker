FROM golang:latest AS builder

RUN go get -v -u github.com/arduino/arduino-cli


# Use the same base distribution as golang to get a compatible libc.
FROM debian:latest AS arduino-cli-base
ARG CORE=esp8266:esp8266

RUN apt update \
  && apt install -y \
    ca-certificates \
    git \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /go/bin/arduino-cli /usr/local/bin

RUN echo '\
board_manager:\n\
  additional_urls:\n\
    - http://arduino.esp8266.com/stable/package_esp8266com_index.json\n'\
  > /usr/local/bin/.cli-config.yml

RUN groupadd -r arduino && useradd --no-log-init --create-home -g arduino arduino
USER arduino
RUN mkdir -p /home/arduino/Arduino/Projects
VOLUME /home/arduino/Arduino/Projects
WORKDIR /home/arduino/Arduino/Projects

RUN arduino-cli core update-index
RUN arduino-cli core install ${CORE}

# Force a trivial build to finish downloading any remaing tools.
RUN arduino-cli sketch new Setup \
  && arduino-cli --fqbn esp8266:esp8266:nodemcuv2 compile /home/arduino/Arduino/Setup \
  && rm -fr /home/arduino/Arduino/Setup

CMD ["/bin/bash", "--login"]


# Prefer the latest esptool over Debian as it is much newer. To keep the image
# slim, we don't normally want the full development suite pulled in by pip.
# * arduino-cli-python: Arduino plus basic Python
# * arduino-cli-esptool-builder: Temp image
# * arduino-cli-esp8266: Arduino plus esptool
FROM arduino-cli-base AS arduino-cli-python
USER root
RUN apt update \
  && apt install -y python3


FROM arduino-cli-python AS arduino-cli-esptool-builder
RUN apt install -y python3-pip \
  && pip3 install esptool


FROM arduino-cli-python AS arduino-cli-esp8266
RUN apt clean && rm -rf /var/lib/apt/lists/*
COPY --from=arduino-cli-esptool-builder /usr/local /usr
USER arduino

