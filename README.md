# AVADO Jellyfin

`jellyfin.avado.dnp.dappnode.eth`: [Jellyfin](https://jellyfin.org) 12.4, a media server for
films, series, music and photos, packaged for AVADO.

- Page: **https://jellyfin.my.ava.do** (plain http works too).
- Image: the official `jellyfin/jellyfin:12.4`, pinned by digest, plus nginx for HTTPS.

## How it is put together

| Part | What |
|---|---|
| `build/Dockerfile` | Official image + `nginx-light`. Jellyfin listens on 8096 inside the container; nginx serves 80 and 443. No host ports. `JELLYFIN_PublishedServerUrl=https://jellyfin.my.ava.do` is the address Jellyfin gives its apps. |
| `build/avado/avado-start.sh` | Start wrapper shared by the AVADO app packages: nginx, the certificate check (15 s after start, then daily), `nice 10` for Jellyfin (and so for the ffmpeg processes it starts). |
| `build/avado/avado-certs.sh` | The `*.my.ava.do` certificate: the box's DAPPMANAGER copy (`http://dappmanager.my.ava.do/my.ava.do.crt`, as AVADO-DNP-Nethermind uses), else `http://iso.ava.do`, else the copy taken at build time. |
| `build/avado/nginx.conf.in` | nginx: no buffering (streaming), websockets. |

Volumes: `config` (settings, users, database), `cache` (transcoding scratch, images), `media`
(the films and music; the library folder to choose in Jellyfin's first-run wizard is `/media`).

## Getting films and music onto the box

Jellyfin has no upload button. Today the owner copies files into the `media` volume with the
Admin's Files tab of this package (upload to `/media`). That works but is not a one-click flow; a
simpler way (an upload page, or a shared network folder) is an open question for the owner.

## Resource use and the Ethereum node

AVADO's package format has no memory or CPU limits (the DAPPMANAGER's compose generator does not
pass `mem_limit`/`cpus`), and no `devices`, so there is no hardware video decoding: converting a
video for a phone or a slow connection uses the processor. Jellyfin and ffmpeg run at `nice 10`, so
the node wins when the processor is busy (playback may pause), and playing a file the device can
play directly uses almost no processor time. Measured on local Docker: about 550 MB of memory
idle.

## Who can reach it

Every device that can open `my.ava.do`: on the AVADO network (AVADO WiFi) or through Remote
Access. No port is opened on the home network, so Jellyfin's automatic server discovery (UDP 7359,
DLNA) does not find it on the home network; apps connect with the address
`https://jellyfin.my.ava.do`.

## Updating

Bump the digest and tag in `build/Dockerfile`, `upstream` and `version` in
`dappnode_package.json` and the image tag in `docker-compose.yml`. Read the Jellyfin release notes
first; the database is migrated automatically on start and cannot be downgraded.

## Licence

The packaging files in this repository are GPL-3.0 (see `LICENSE`). Jellyfin is GPL-2.0 and is used
unchanged from its official image. The avatar is the Jellyfin logo.
