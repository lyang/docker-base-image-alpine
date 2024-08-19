FROM alpine:3.20 AS rootfs-stage

ARG ALPINE_VERSION="v3.20"
ARG ARCH="x86_64"
ENV ROOTFS=/root-out
ENV MIRROR=https://dl-cdn.alpinelinux.org/alpine
ENV PACKAGES=alpine-baselayout,alpine-keys,apk-tools,busybox,libc-utils,shadow

RUN mkdir -p "$ROOTFS/etc/apk"
RUN echo "$MIRROR/$ALPINE_VERSION/main" >> "$ROOTFS/etc/apk/repositories"
RUN echo "$MIRROR/$ALPINE_VERSION/community" >> "$ROOTFS/etc/apk/repositories"
RUN apk --root "$ROOTFS" --no-cache --keys-dir /etc/apk/keys add --arch $ARCH --initdb ${PACKAGES//,/ }
RUN sed -i -e "s/^root::/root:!:/" /root-out/etc/shadow

ARG S6_OVERLAY_VERSION="3.2.0.0"

RUN apk add --no-cache bash xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C $ROOTFS -Jxpf /tmp/s6-overlay-noarch.tar.xz

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-$ARCH.tar.xz /tmp
RUN tar -C $ROOTFS -Jxpf /tmp/s6-overlay-$ARCH.tar.xz

FROM scratch
COPY --from=rootfs-stage /root-out/ /
COPY /root /
ARG GID=1000
ARG UID=1000
RUN addgroup --system --gid $GID app && adduser --system --uid $UID --ingroup app --home /app app
ENTRYPOINT ["/init"]
