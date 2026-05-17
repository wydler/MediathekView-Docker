#!/bin/sh

#
# Customizing Mediathekview
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

#
if [ ! -f /config/bookmarks.json ]; then
    cat <<EOF > /config/bookmarks.json
{
  "bookmarks" : [ ]
}
EOF
fi


# Prüft, ob die Datei /config/settings.xml existiert.
# Falls ja, wird der Wert von <settings><application><notifications><show> auf "false" gesetzt
# Mithilfe von xmlstarlet, um Benachrichtigungen in der Konfiguration zu deaktivieren.
if [ -f /config/settings.xml ]; then
    # Prüfen, ob <notifications> unter <settings>/<application> existiert, sonst hinzufügen
    if ! xmlstarlet sel -t -v "count(/settings/application/notifications)" /config/settings.xml | grep -q '^1$'; then
        xmlstarlet ed -L -s "/settings/application" -t elem -n "notifications" -v "" /config/settings.xml
    fi

    # Prüfen, ob <show> unter <notifications> existiert, sonst hinzufügen oder Wert setzen
    if xmlstarlet sel -t -v "count(/settings/application/notifications/show)" /config/settings.xml | grep -q '^1$'; then
        # <show> existiert → Wert auf false setzen
        xmlstarlet ed -L -u "/settings/application/notifications/show" -v "false" /config/settings.xml
    else
        # <show> existiert nicht → Element hinzufügen
        xmlstarlet ed -L -s "/settings/application/notifications" -t elem -n "show" -v "false" /config/settings.xml
    fi
fi


# Setze das Home-Verzeichnis des Users "app" von /dev/null auf /output,
# damit der Benutzer ein gültiges Home-Verzeichnis im Volume erhält
sed -i '/^app:/ s|/dev/null|/output/|' /etc/passwd

#
# Rechte setzen
chown -R app:app /config /output


#
# https://stackoverflow.com/questions/76328891/how-to-redirect-where-javafx-caches-dll-libraries
if ! grep -q "\-Djavafx.cachedir=${JAVAFX_TMP_DIR}" "/opt/MediathekView/MediathekView.vmoptions"; then

    cat <<EOF >> /opt/MediathekView/MediathekView.vmoptions
#
# Set custom path for the OpenFx cache files
-Djavafx.cachedir=${JAVAFX_TMP_DIR}
EOF
fi


#
# https://stackoverflow.com/questions/65819206/hosting-javafx-project-on-docker-container
if [ "${JAVAFX_GLX_DISABLE:-0}" -eq 1 ]; then

    if ! grep -q "\-Dprism.order=sw" "/opt/MediathekView/MediathekView.vmoptions"; then

        cat <<EOF >> /opt/MediathekView/MediathekView.vmoptions
#
# Disabling the hardware graphics acceleration
-Dprism.order=sw
EOF
    fi

else
    sed -e '/\# Disabling the hardware graphics acceleration/d' -i /opt/MediathekView/MediathekView.vmoptions
    sed -e '/\-Dprism.order=sw/d' -i /opt/MediathekView/MediathekView.vmoptions
fi


# Disable automatic update for Mediathekview
echo "127.0.0.1       download.mediathekview.de" >> /etc/hosts
