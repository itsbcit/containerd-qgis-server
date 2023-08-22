FROM bcit.io/alpine:latest as build

WORKDIR /src

COPY DataPlotly-4.0.0.zip .
COPY lizmap_server-2.7.1.zip .
COPY qgis_server_render_geojson-v0.4.zip .

RUN ls -alh

RUN unzip DataPlotly-4.0.0.zip \
  && unzip lizmap_server-2.7.1.zip \
  && unzip qgis_server_render_geojson-v0.4.zip \
  && ls -alh

FROM debian:bullseye-slim
LABEL maintainer="jesse@weisner.ca, chriswood.ca@gmail.com"
LABEL build_id="1692740113"

# Add docker-entrypoint script base
ADD https://github.com/itsbcit/docker-entrypoint/releases/download/v1.5/docker-entrypoint.tar.gz /docker-entrypoint.tar.gz
RUN tar zxvf docker-entrypoint.tar.gz && rm -f docker-entrypoint.tar.gz \
 && chmod -R 555 /docker-entrypoint.* \
 && echo "UTC" > /etc/timezone \
 && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
 && chmod 664 /etc/passwd \
              /etc/group \
              /etc/shadow \
              /etc/timezone \
              /etc/localtime \
 && chown 0:0 /etc/shadow \
 && chmod 775 /etc

# Add Tini
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-amd64 /tini
RUN chmod +x /tini \
 && ln -s /tini /sbin/tini 


ENV LANG=en_EN.UTF-8


RUN apt-get --assume-yes update \
    && apt-get install --no-install-recommends --no-install-suggests --allow-unauthenticated -y \
        gnupg \
        ca-certificates \
        wget \
        locales \
        python3-pip \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    # Add the current key for package downloading
    # Please refer to QGIS install documentation (https://www.qgis.org/fr/site/forusers/alldownloads.html#debian-ubuntu)
    && mkdir -m755 -p /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg \
    # Add repository for latest version of qgis-server
    # Please refer to QGIS repositories documentation if you want other version (https://qgis.org/en/site/forusers/alldownloads.html#repositories)
    && echo "deb [signed-by=/etc/apt/keyrings/qgis-archive-keyring.gpg] https://qgis.org/debian bullseye main" | tee /etc/apt/sources.list.d/qgis.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --allow-unauthenticated -y \
        qgis-server \
        spawn-fcgi \
        xauth \
        xvfb \
    && apt-get remove --purge -y \
        gnupg \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m qgis

ENV QGIS_PREFIX_PATH /usr
ENV QGIS_SERVER_LOG_STDERR 1
ENV QGIS_SERVER_LOG_LEVEL 2
ENV QGIS_RENDERGEOJSON_PREFIX /usr/lib/qgis/plugins/qgis_server_render_geojson

COPY --chown=qgis:qgis cmd.sh /home/qgis/cmd.sh
RUN chmod -R 777 /home/qgis/cmd.sh /usr/lib/qgis/plugins
COPY --from=build --chown=qgis:qgis /src/DataPlotly/ /usr/lib/qgis/plugins/DataPlotly
COPY --from=build --chown=qgis:qgis /src/lizmap_server/ /usr/lib/qgis/plugins/lizmap_server
COPY --from=build --chown=qgis:qgis /src/qgis_server_render_geojson/ /usr/lib/qgis/plugins/qgis_server_render_geojson
RUN ls -alh /usr/lib/qgis/plugins/

# setup qgis-plugin-manager and upgrade qgis plugins
ENV QGIS_PLUGINPATH /usr/lib/qgis/plugins/
RUN pip3 install qgis-plugin-manager
RUN cd /usr/lib/qgis/plugins
RUN qgis-plugin-manager init
RUN qgis-plugin-manager update
RUN qgis-plugin-manager upgrade

USER qgis
WORKDIR /home/qgis

ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]

CMD ["/home/qgis/cmd.sh"]
# CMD [ "init-loop" ]
