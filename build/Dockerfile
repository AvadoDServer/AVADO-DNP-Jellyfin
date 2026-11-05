# Jellyfin 12.4, the official image (Debian 13), pinned by digest.
FROM --platform=linux/amd64 jellyfin/jellyfin:12.4@sha256:fea863d0cd9ec445985d9c75fc6ed64e38a1d2766cf0c250a33d553f4fc1b771

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx-light \
 && rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/default

# HTTPS front: the *.my.ava.do certificate, refreshed at start from the box.
RUN mkdir -p /etc/avado/certs \
 && curl -fsS -o /etc/avado/certs/build.crt http://iso.ava.do/my.ava.do.crt \
 && curl -fsS -o /etc/avado/certs/build.key http://iso.ava.do/my.ava.do.key \
 && openssl x509 -in /etc/avado/certs/build.crt -noout -subject
COPY avado/ /etc/avado/
RUN chmod +x /etc/avado/*.sh

# A link to "Add films and music" in Jellyfin's own menu.
RUN sed -i 's|"menuLinks": \[\]|"menuLinks": [{ "name": "Add films and music", "icon": "file_upload", "url": "/avado-upload/" }]|' \
      /jellyfin/jellyfin-web/config.json \
 && grep -q '"Add films and music"' /jellyfin/jellyfin-web/config.json

# The address Jellyfin gives its apps when they find it.
ENV JELLYFIN_PublishedServerUrl=https://jellyfin.my.ava.do

ENTRYPOINT ["/etc/avado/avado-start.sh"]
CMD ["/jellyfin/jellyfin"]
