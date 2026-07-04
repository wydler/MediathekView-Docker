# ----------------------------------------
# Stage 1: Build / Download MediathekView
# ----------------------------------------
FROM debian:13.5-slim@sha256:28de0877c2189802884ccd20f15ee41c203573bd87bb6b883f5f46362d24c5c2 AS builder

# ----------------------------------------
# Build-Argument
# ----------------------------------------
ARG TARGETARCH

# Setze Arbeitsverzeichnis für temporäre Dateien
WORKDIR /tmp

# ----------------------------------------
# Kopiere nur die mediathekview.version
# Diese enthält die gewünschte MediathekView-Version
# ----------------------------------------
COPY mediathekview.version /tmp/mediathekview.version

# ----------------------------------------
# Installiere wget und ca-certificates für HTTPS-Download
# --no-install-recommends hält das Image klein
# ----------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------------------
# Create /opt/MediathekView directory and download the correct MediathekView archive
# based on the build target architecture (TARGETARCH).  
# - For arm64 builds, use "linux-aarch64" archive  
# - For amd64 builds, use "linux" archive  
# Then extract the archive to /opt and clean up temporary files.
# ----------------------------------------
RUN mkdir -p /opt/MediathekView \
 && case "$TARGETARCH" in \
      arm64) ARCH="linux-aarch64" ;; \
      amd64) ARCH="linux" ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
 && wget -q "https://download.mediathekview.de/stabil/MediathekView-$(cat /tmp/mediathekview.version)-${ARCH}.tar.gz" -O /tmp/MediathekView.tar.gz \
 && tar xf /tmp/MediathekView.tar.gz -C /opt \
 && rm /tmp/MediathekView.tar.gz /tmp/mediathekview.version


# ----------------------------------------
# Stage 2: Runtime
# ----------------------------------------
FROM jlesage/baseimage-gui:debian-13-v4.12.5@sha256:17f2e04d15fb5070ab780ad9c4928809ef28e8acc88cbe24f62879a60e549618

# Build-Argument
ARG APP_VERSION
ARG DOCKER_IMAGE_VERSION

# ----------------------------------------
# Metadata / Labels
# ----------------------------------------
LABEL maintainer="Daniel Wydler" \
      org.opencontainers.image.authors="Daniel Wydler" \
      org.opencontainers.image.description="MediathekView durchsucht Online-Mediatheken öffentlich-rechtlicher Sender." \
      org.opencontainers.image.documentation="https://github.com/wydler/MediathekView-Docker/blob/master/README.md" \
      org.opencontainers.image.source="https://github.com/wydler/MediathekView-Docker" \
      org.opencontainers.image.title="wydler/mediathekview" \
      org.opencontainers.image.url="https://hub.docker.com/r/wydler/mediathekview"

# ----------------------------------------
# Setze Umgebungsvariablen
# LC_ALL/Language für UTF-8 Support
# JAVAFX_TMP_DIR für JavaFX Cache
# TERM und S6_KILL_GRACETIME für Baseimage-GUI
# ----------------------------------------
ENV APP_NAME="Mediathekview" \
    APP_VERSION=$APP_VERSION \
    DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION \
    USER_ID=0 \
    GROUP_ID=0 \
    TERM=xterm \
    S6_KILL_GRACETIME=8000 \
    JAVAFX_TMP_DIR=/tmp/openjfx/cache \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LANG=en_US.UTF-8

# ----------------------------------------
# Kopiere die entpackten MediathekView-Dateien aus der Build-Stage
# ----------------------------------------
COPY --from=builder /opt/MediathekView /opt/MediathekView

# ----------------------------------------
# Installiere nur die Runtime-Pakete
# VLC, FFmpeg, flvstreamer und procps werden für die App benötigt
# ----------------------------------------
RUN add-pkg \
    locales \
    vlc \
    ca-certificates \
    ffmpeg \
    flvstreamer \
    procps \
    libnotify4 \
    libxtst6 \
    xmlstarlet \
    libgtk-3-0

# ----------------------------------------
# Generiere die en_US.UTF-8 Locale, damit UTF-8 Zeichen korrekt unterstützt werden
# und Bash/Java-Anwendungen keine "cannot change locale"-Warnings ausgeben
# ----------------------------------------
RUN echo en_US.UTF-8 UTF-8 > /etc/locale.gen \
    && locale-gen

# ----------------------------------------
# RootFS & Permissions
# ----------------------------------------
COPY rootfs /

RUN chmod 755 \
    /etc/cont-init.d/90-mediathekview.sh \
    /startapp.sh

# ----------------------------------------
# Definierte Mountpoints für persistente Daten
# /config: Konfiguration
# /output: heruntergeladene Medien
# ----------------------------------------
VOLUME ["/config", "/output"]