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

# First start only: name the server "AVADO" (Jellyfin's apps show this name;
# otherwise it is the container's random host name) and make the four
# libraries the "Add films and music" page fills, so Jellyfin's home page
# shows them instead of asking the owner to make a library with folder paths.
if [ ! -e /config/config/system.xml ]; then
  mkdir -p /config/config
  cat > /config/config/system.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ServerConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <ServerName>AVADO</ServerName>
</ServerConfiguration>
EOF
fi
if [ ! -e /config/root/default ]; then
  for _lib in "Films|Films|movies" "Series|Series|tvshows" "Music|Music|music" \
              "Home videos and photos|Photos|homevideos"; do
    _name=${_lib%%|*}; _rest=${_lib#*|}; _dir=${_rest%%|*}; _type=${_rest#*|}
    mkdir -p "/config/root/default/$_name"
    printf '%s' "/media/$_dir" > "/config/root/default/$_name/$_name.mblink"
    : > "/config/root/default/$_name/$_type.collection"
    cat > "/config/root/default/$_name/options.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<LibraryOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Enabled>true</Enabled>
  <EnablePhotos>true</EnablePhotos>
  <PathInfos>
    <MediaPathInfo>
      <Path>/media/$_dir</Path>
    </MediaPathInfo>
  </PathInfos>
</LibraryOptions>
EOF
  done
  echo "[avado] first start: server named AVADO, libraries Films, Series, Music, Home videos and photos made"
fi
