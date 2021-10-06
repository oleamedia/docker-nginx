
ARG ALPINE_VERSION=3.14

FROM alpine:${ALPINE_VERSION}

LABEL maintainer="Oleamedia <info@oleamedia.com>"

ARG NGINX_RTMP_VERSION=1.2.1
ARG REPO=dl-cdn
ARG UID=101
ARG GID=101

ENV TZ=America/New_York

RUN set -x && \
  addgroup -g ${GID} -S nginx && adduser -u ${UID} -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx && \
  sed -i "s/dl-cdn.alpinelinux.org/${REPO}.alpinelinux.org/g" /etc/apk/repositories && \
  RUN_DEPS=" \
      bash \
      tzdata \
      ca-certificates \
      yasm \
      libaio \
      ffmpeg \
      libaio-dev \
      rtmpdump-dev \
      musl-dev \
      lame-dev \
      libtheora-dev \
      libvorbis-dev \
      libvpx-dev \
      freetype-dev \
      x264-dev \
      x265-dev \
  " && \
  \
  apk add --no-cache --virtual $RUN_DEPS && \
  apk add --no-cache --virtual .build-deps \
      git \
      curl \
      tzdata \
      samurai \
      libstdc++ \
      build-base \
      linux-headers \
      go \
      gcc \
      make \
      cmake \
      gnupg1 \
      geoip \
      #libuuid \
      openssl-dev \
      pcre-dev \
      zlib-dev \
      perl-dev \
      libc-dev \
      libunwind-dev \
      libxslt-dev \
      gd-dev \
      geoip-dev \
      perl-dev && \
  \
  CONFIG="\
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/usr/lib/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --http-client-body-temp-path=/var/cache/nginx/client_temp \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
      --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
      --user=nginx \
      --group=nginx \
      --with-http_ssl_module \
      --with-http_realip_module \
      --with-http_addition_module \
      --with-http_sub_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_random_index_module \
      --with-http_secure_link_module \
      --with-http_stub_status_module \
      --with-http_auth_request_module \
      --with-http_xslt_module \
      --with-http_image_filter_module \
      --with-http_geoip_module \
      --with-threads \
      --with-stream \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
      --with-stream_realip_module \
      --with-stream_geoip_module \
      --with-http_slice_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-compat \
      --with-file-aio \
      --with-http_v2_module \
      --with-http_v3_module \
      --with-http_quic_module \
      --with-stream_quic_module \
      --add-module=nginx-rtmp \
      --add-module=ngx_brotli \
      --add-module=njs/nginx \
      --add-module=headers-more-nginx-module \
      --add-module=nginx_cookie_flag_module \
  " && \
  \
  cd /tmp && \
  wget -c https://hg.nginx.org/nginx-quic/archive/quic.tar.gz -O - | tar -xz && \
  mv nginx* nginx && \
  cd nginx && \
  git clone --depth=1 -b master https://github.com/google/boringssl boringssl && \
  cd boringssl && \
  mkdir build && \
  cd build && \
  cmake -GNinja .. && \
  ninja && \
  cd /tmp/nginx && \
  git clone https://github.com/google/ngx_brotli --depth=1 && \
  cd ngx_brotli && git submodule update --init && \
  export NGX_BROTLI_STATIC_MODULE_ONLY=1 && \
  cd /tmp/nginx && \
  mkdir /usr/local/share/GeoIP/ && \
  wget -c https://raw.githubusercontent.com/openbridge/nginx/master/geoip/GeoLiteCity.dat.gz -O - | gzip -d > /usr/local/share/GeoIP/GeoLiteCity.dat && \
  wget -c https://raw.githubusercontent.com/openbridge/nginx/master/geoip/GeoIP.dat.gz -O - | gzip -d > /usr/local/share/GeoIP/GeoIP.dat && \
  chown -R nginx: /usr/local/share/GeoIP/ && \
  wget -c https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz -O - | tar -xz && \
  mv nginx-rtmp* nginx-rtmp && \
  git clone https://github.com/nginx/njs --depth=1 && \
  git clone https://github.com/openresty/headers-more-nginx-module --depth=1 && \
  git clone https://github.com/AirisX/nginx_cookie_flag_module --depth=1 && \
  \
  ./auto/configure $CONFIG \
      --with-cc-opt="-I boringssl/include -Wimplicit-fallthrough=0" \
      --with-ld-opt="-L boringssl/build/ssl  -L boringssl/build/crypto" && \
  make -j$(getconf _NPROCESSORS_ONLN) && \
  make install && \
  rm -rf /etc/nginx/html/index.html && \
  mkdir /etc/nginx/conf.d/ && \
  mkdir /etc/nginx/sites-available/ && \
  mkdir /etc/nginx/sites-enabled/ && \
  git clone https://github.com/nbs-system/naxsi --depth=1 && \
  cd naxsi && \
  mv naxsi_config/naxsi_core.rules /etc/nginx/naxsi_core.rules && \
  ln -s /usr/lib/nginx/modules /etc/nginx/modules && \
  strip /usr/sbin/nginx* && \
  apk add --no-cache --virtual .gettext gettext && \
  mv /usr/bin/envsubst /tmp/ && \
  \
  runDeps="$( \
  scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
  | tr ',' '\n' \
  | sort -u \
  | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )" && \
  mv /tmp/envsubst /usr/local/bin/ && \
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  \
  ln -snf /user/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone && \
  apk add --no-cache --virtual .nginx-rundeps $runDeps && \
  apk del --no-network .build-deps && \
  apk del --no-network .gettext && \
  rm -rf /tmp/*

EXPOSE 80
EXPOSE 443
EXPOSE 1935
EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
