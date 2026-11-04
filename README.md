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
| `build/avado/nginx.conf.in` | nginx: no buffering (streaming), websockets, the upload page, a "Jellyfin is starting" page (`build/avado/www/`) instead of a 502 while Jellyfin starts. |
| `build/avado/app-prestart.sh` | Creates the upload folders in the media volume. On a fresh install it also names the server `AVADO` (`system.xml`; otherwise Jellyfin and its apps show the container's random host name) and makes the four libraries (Films, Series, Music, Home videos and photos), so Jellyfin's home page shows them instead of sending the owner to library settings with folder paths. |

Volumes: `config` (settings, users, database), `cache` (transcoding scratch, images), `media`
(the films and music, in `Films`, `Series`, `Music` and `Photos`).

## Getting films and music onto the box: "Add films and music"

Jellyfin has no upload button, and the Admin's Files tab cannot carry films (it sends a file
through the Admin's websocket in one piece). So the package has its own small page at
**https://jellyfin.my.ava.do/avado-upload/** (`build/avado/upload/index.html`, served by the nginx
in the container; also in the store links and as "Add films and music" in Jellyfin's own menu, through `menuLinks` in jellyfin-web's `config.json`):

1. It uses the owner's Jellyfin sign-in from Jellyfin's own page in the same browser, or asks for
   the Jellyfin user name and password. Only a Jellyfin **administrator** may upload.
2. The owner picks a kind (Films, Series, Music, Home videos and photos) and files or a folder
   (folder uploads keep their sub-folders, which Jellyfin needs for series and albums). Phones and
   tablets cannot pick a folder, so there the page offers files only (no "Choose a folder").
3. The libraries exist from the first start. If the owner removed one, the next upload of that kind
   makes it again (`/media/Films`, `/media/Series`, `/media/Music`, `/media/Photos`) unless a library
   already covers that folder or all of `/media`.
4. Each file is sent with one HTTP `PUT` straight into the media volume (nginx WebDAV `PUT` only;
   no size limit; the temporary file is in the same volume so nothing is copied twice), with a
   progress bar. Afterwards the page asks Jellyfin to scan the libraries.
5. Before each file the page asks Jellyfin how much disk space is left (`/System/Info/Storage`,
   administrators only) and refuses the file if less than 15% of the disk, or 100 GB, whichever is
   more, would stay free: the media volume shares the disk with the Ethereum node, which keeps
   growing. This is a check in the page, not in nginx, so it protects owners from filling the disk
   by mistake; it is not a security limit.

Safety: nginx asks Jellyfin before accepting a file (`auth_request` to `/Library/VirtualFolders`,
which answers only administrators: no sign-in 401, a normal user 403). Only `PUT` into those four
folders is possible: nothing can be read, listed or deleted through it, and paths outside them are
refused (tested: `..`, encoded `..`, other folders). A file with the same name is replaced.
`build/avado/app-prestart.sh` creates the folders and gives them to the nginx user; Jellyfin
reads them. Temporary files of cut-off uploads are removed after a day. The page is served over
https only: `http://jellyfin.my.ava.do/avado-upload/...` redirects to https (the sign-in and the
files must not go over plain http). The rest of Jellyfin still answers on http as well, for TV
apps set up with an http address.

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
