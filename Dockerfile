FROM openjdk:19-jdk-alpine3.15
MAINTAINER ccx0lw <fcjava@163.com>

ENV DEBIAN_FRONTEND noninteractive

ENV LANG=C.UTF-8

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.32-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

RUN apk add --no-cache bash shadow sudo curl linux-pam ca-certificates libintl gettext && \
            update-ca-certificates && \
            ln -s /lib /lib64 && \
            addgroup sudo
            
RUN apk add --virtual .build-deps build-base automake autoconf libtool linux-pam-dev openssl-dev wget unzip

# 安装 conda
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV CONTAINER_UID 1000
ENV INSTALLER Miniconda3-latest-Linux-x86_64.sh
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    echo $(wget --quiet -O - https://repo.continuum.io/miniconda/ \
    | grep -A3 $INSTALLER \
    | tail -n1 \
    | cut -d\> -f2 \
    | cut -d\< -f1 ) $INSTALLER  && \
    /bin/bash $INSTALLER -f -b -p $CONDA_DIR && \
    rm $INSTALLER

# python3
RUN conda install -y python=3 && \
    conda update conda && \
    conda clean --all --yes

# jupyterhub ... 
RUN conda install -c conda-forge -c pytorch -c krinsman -c beakerx jupyterhub jupyterlab notebook nbgitpuller && \
    conda update --all && \
    conda clean --all --yes

RUN apk add ruby-dev

# RUN gem install -N gallery-ruby-kernel && \ 
#     rm /usr/lib/ruby/gems/*/cache/*

RUN gem update --system
RUN gem install compass
RUN gem install cztop rbczmq ffi-rzmq 
RUN gem install iruby
RUN iruby register --force

CMD ["node -v"]
