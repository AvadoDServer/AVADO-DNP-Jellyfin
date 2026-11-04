# Jellyfin on AVADO: sourced by avado-start.sh before Jellyfin starts.
#
# The "Add films and music" page (nginx, user www-data) writes uploads into
# these folders of the media volume; Jellyfin (root) reads them.
for _d in Films Series Music Photos .avado-upload-tmp; do
  mkdir -p "/media/$_d"
done
chown "$NGINX_USER" /media/Films /media/Series /media/Music /media/Photos /media/.avado-upload-tmp
chmod 700 /media/.avado-upload-tmp
# Uploads that were cut off leave temporary files behind.
find /media/.avado-upload-tmp -type f -mtime +1 -delete 2>/dev/null
