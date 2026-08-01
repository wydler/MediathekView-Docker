# MediathekView
[![Docker Image Version (tag latest)](https://img.shields.io/docker/v/wydler/mediathekview/latest)](https://hub.docker.com/r/wydler/mediathekview) [![Docker Image Size (tag latest)](https://img.shields.io/docker/image-size/wydler/mediathekview/latest)](https://hub.docker.com/r/wydler/mediathekview) [![Docker Pulls](https://img.shields.io/docker/pulls/wydler/mediathekview)](https://hub.docker.com/r/wydler/mediathekview) [![Docker Stars](https://img.shields.io/docker/stars/wydler/mediathekview)](https://hub.docker.com/r/wydler/mediathekview)

## Overview
The program MediathekView searches the online media libraries of various public broadcasters.  
This is a port to a Docker container. The container is based on the project [docker-baseimage-gui](https://github.com/jlesage/docker-baseimage-gui).


## Requirements
* Docker & Docker Compose V2
* SSH/Terminal access (able to install commands/functions if non-existent)


## Install Docker, download containers und configure application
1. This script will install docker and containerd:
  ```
  curl https://raw.githubusercontent.com/wydler/MediathekView-Docker/refs/heads/master/misc/02-docker.io-installation.sh | bash
  ```
2. For IPv6 support, edit the Docker daemon configuration file, located at `/etc/docker/daemon.json`. Configure the following parameters and run `systemctl restart docker.service` to restart docker:
  ```
  {
    "experimental": true,
    "ip6tables": true
  }
  ```
3. Clone the repository to the correct folder for docker container:
  ```
  git clone https://github.com/wydler/MediathekView-Docker.git /opt/containers/mediathekview
  git -C /opt/containers/mediathekview checkout $(git -C /opt/containers/mediathekview tag | tail -1)
  ```
4. Create docker-compose.yml and .env file:
  ```
  cp /opt/containers/mediathekview/.env.example /opt/containers/mediathekview/.env
  cp /opt/containers/mediathekview/docker-compose.yml.example /opt/containers/mediathekview/docker-compose.yml
  ```
5. Editing `/opt/containers/mediathekview/.env` and set your parameters and data. Any change requires an restart of the containers.
6. Editing `/opt/containers/mediathekview/docker-compose.yml` and set your parameters (e.g., specify an explicit tag, public port, etc.).
7. Starting application with `docker compose -f /opt/containers/mediathekview/docker-compose.yml up -d`.
8. Don't forget to test, that the application works successfully (e.g. http://FQDN:5800/).
## Update Repo and docker image

1. Update Git Repository to latest release:
  ```
  git -C /opt/containers/mediathekview pull
  git -C /opt/containers/mediathekview checkout $(git -C /opt/containers/mediathekview tag | tail -1)
  ```
2. Update docker image to latest release:
  ```
  docker image pull wydler/mediathekview:latest
  ```
3. (Re)start container:
  ```
  docker compose -f docker compose -f /opt/containers/mediathekview/docker-compose.yml up -d --force-recreate
  ```

## Cosign
Cosign is a command-line tool from the Sigstore project used to sign and verify software artifacts such as container images. It enables the digital signing of artifacts to guarantee their origin and integrity. Signed artifacts can be stored in the registry, and verification is possible using public-key/private-key cryptography.

### Installation with dpkg package
```bash
LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb"
sudo dpkg -i cosign_${LATEST_VERSION}_amd64.deb
```
[Source](https://docs.sigstore.dev/cosign/system_config/installation/#with-the-cosign-binary-or-rpmdpkg-package)

### Verifying Signature
Verify with an on-disk public key provided by the signer:
```bash
DOCKER_REPOSITORY=wydler/mediathekview
GITHUB_REPOSITORY=wydler/MediathekView-Docker

TAG=$(curl -fsS https://api.github.com/repos/${GITHUB_REPOSITORY}/releases | grep '"tag_name"' | cut -d'"' -f4 | head -n1)
curl -O -L https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/refs/tags/${TAG}/cosign.pub

DOCKER_TOKEN=$(curl -fsS "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${DOCKER_REPOSITORY}:pull" | jq -r '.token')

INDEX_DIGEST_SHA=$(curl -fsSI \
  -H "Authorization: Bearer ${DOCKER_TOKEN}" \
  -H "Accept: application/vnd.oci.image.index.v1+json" \
  "https://registry-1.docker.io/v2/${DOCKER_REPOSITORY}/manifests/${TAG}" \
  | awk -F': ' 'tolower($1)=="docker-content-digest" {print $2}' \
  | tr -d '\r'
  )

RESULT=$(cosign verify --key cosign.pub docker.io/${DOCKER_REPOSITORY}:${TAG}@${INDEX_DIGEST_SHA})
echo $RESULT | jq .

rm cosign.pub
```
Hint: The third line finds the name of the latest release on GitHub. If you want to check an older version, statically assign the desired version number to the variable `TAG` (e.g., `TAG=14.5.0-0009`).

## Notice
On the very first start of the container (no Mediathekview configuration present), error messages appear in the container's log.

### Error when get server info
This is due to the fact that the "Show notifications" parameter is enabled by default in MediathekView's settings.  
```
. Failed to initialize libNotify
mediathekview  | [app          ] java.lang.RuntimeException: Error when get server info
mediathekview  | [app          ]        at es.blackleg.jlibnotify.core.DefaultJLibnotify.getServerInfo(DefaultJLibnotify.java:77) ~[jlibnotify-1.2.1.jar:?]
mediathekview  | [app          ]        at mediathek.tool.notification.LinuxNotificationCenter.<init>(LinuxNotificationCenter.java:25) [MediathekView.jar:?]
mediathekview  | [app          ]        at mediathek.x11.MediathekGuiX11.getNotificationCenter(MediathekGuiX11.java:51) [MediathekView.jar:?]
mediathekview  | [app          ]        at mediathek.mainwindow.MediathekGui.setupNotificationCenter(MediathekGui.java:457) [MediathekView.jar:?]
mediathekview  | [app          ]        at mediathek.mainwindow.MediathekGui.<init>(MediathekGui.java:207) [MediathekView.jar:?]
mediathekview  | [app          ]        at mediathek.x11.MediathekGuiX11.<init>(MediathekGuiX11.java:19) [MediathekView.jar:?]
mediathekview  | [app          ]        at mediathek.Main.getPlatformWindow(Main.java:814) [MediathekView.jar:?]
mediathekview  | [app          ]        at mediathek.Main.startGuiMode(Main.java:791) [MediathekView.jar:?]
mediathekview  | [app          ]        at mediathek.Main.lambda$main$0(Main.java:545) [MediathekView.jar:?]
mediathekview  | [app          ]        at java.desktop/java.awt.event.InvocationEvent.dispatch(InvocationEvent.java:318) [?:?]
mediathekview  | [app          ]        at java.desktop/java.awt.EventQueue.dispatchEventImpl(EventQueue.java:723) [?:?]
mediathekview  | [app          ]        at java.desktop/java.awt.EventQueue.dispatchEvent(EventQueue.java:702) [?:?]
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpOneEventForFilters(EventDispatchThread.java:203) [?:?]
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpEventsForFilter(EventDispatchThread.java:124) [?:?]
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpEventsForHierarchy(EventDispatchThread.java:113) [?:?]
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpEvents(EventDispatchThread.java:109) [?:?]
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpEvents(EventDispatchThread.java:101) [?:?]
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.run(EventDispatchThread.java:90) [?:?]
```
The parameter is disabled the next time the container is started.


### AWT-EventQueue-0
This message appears the first time you download the movie list.

```
mediathekview  | [app          ] Exception in thread "AWT-EventQueue-0" java.util.ConcurrentModificationException
mediathekview  | [app          ]        at java.base/java.util.ArrayList$Itr.checkForComodification(ArrayList.java:1096)
mediathekview  | [app          ]        at java.base/java.util.ArrayList$Itr.next(ArrayList.java:1050)
mediathekview  | [app          ]        at mediathek.daten.ListeDownloads.abosSuchen(ListeDownloads.java:353)
mediathekview  | [app          ]        at mediathek.gui.tabs.tab_downloads.GuiDownloads.updateDownloads(GuiDownloads.java:542)
mediathekview  | [app          ]        at mediathek.gui.tabs.tab_downloads.GuiDownloads$6.fertig(GuiDownloads.java:1050)
mediathekview  | [app          ]        at mediathek.filmlisten.FilmeLaden.lambda$notifyFertig$0(FilmeLaden.java:404)
mediathekview  | [app          ]        at java.desktop/java.awt.event.InvocationEvent.dispatch(InvocationEvent.java:318)
mediathekview  | [app          ]        at java.desktop/java.awt.EventQueue.dispatchEventImpl(EventQueue.java:723)
mediathekview  | [app          ]        at java.desktop/java.awt.EventQueue.dispatchEvent(EventQueue.java:702)
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpOneEventForFilters(EventDispatchThread.java:203)
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpEventsForFilter(EventDispatchThread.java:124)
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpEventsForHierarchy(EventDispatchThread.java:113)
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpEvents(EventDispatchThread.java:109)
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.pumpEvents(EventDispatchThread.java:101)
mediathekview  | [app          ]        at java.desktop/java.awt.EventDispatchThread.run(EventDispatchThread.java:90)
```