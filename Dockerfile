##
##
## 20150223
##   CentOS 7.6
##   Apache 2.4
##   PHP 7.4X
# https://w.atwiki.jp/sanosoft/pages/92.html
FROM centos:centos7.9.2009 as builder

RUN yum install -y epel-release

# (1) IUSリポジトリのインストール
RUN yum install -y https://repo.ius.io/ius-release-el7.rpm

RUN yum install -y gcc gcc-g++ git make mercurial openssl openssl-devel

WORKDIR /usr/src

# ■ curl
ADD src/curl-7.75.0.tar.bz2 /usr/src/
ADD shell/setup_curl.sh /setup_curl.sh
RUN chmod +x /setup_curl.sh
RUN /setup_curl.sh

# ■ FDインストール
ADD src/FD-3.01j.tar.gz /usr/src/
ADD shell/setup_fd.sh /setup_fd.sh
RUN chmod +x /setup_fd.sh
RUN /setup_fd.sh

FROM centos:centos7.9.2009

RUN yum install -y epel-release

# (1) IUSリポジトリのインストール
# (2) /etc/mime.types
# (3) perl
# (4) nghttp2
# (5) openldap-devel
# (6) expat-devel
# (7) system-logos
# (8) libdb-devel
# (9) brotli
# (10)) Apache2.4のインストール

RUN yum install -y https://repo.ius.io/ius-release-el7.rpm && \
    yum install -y mailcap && \
    yum install -y perl perl-devel && \
    yum --enablerepo=epel install -y nghttp2 libev-devel libnghttp2-devel && \
    yum install -y openldap openldap-devel && \
    yum install -y expat expat-devel && \
    yum install -y system-logos && \
    yum install -y libdb libdb-devel && \
    yum localinstall -y http://dl.marmotte.net/rpms/redhat/el7/x86_64/brotli-1.0.7-1.el7/brotli-1.0.7-1.el7.x86_64.rpm && \
    yum -y install openssl openssl-devel && \
    yum --disablerepo=base,extras,updates --enablerepo=ius install -y httpd httpd-devel mod_ssl

WORKDIR /usr/src

RUN yum install -y gcc gcc-g++ git make mercurial vim supervisor

# ■ curl
WORKDIR /usr/src/curl-7.75.0
COPY --from=builder /usr/src/curl-7.75.0 .
RUN make install

# ■ FDインストール
WORKDIR /usr/src/FD-3.01j
COPY --from=builder /usr/src/FD-3.01j .
RUN make install

# remiリポジトリの公開鍵を取り込む
RUN rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi

# yum-config-manager コマンドのインストールと remiリポジトリの追加
# PHP と拡張モジュールなどをインストール
RUN yum install -y yum-utils https://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
    yum -y install --enablerepo=remi,epel,remi-php74 php php-devel php-intl php-mbstring php-pdo php-pgsql php-xml #php-gd

WORKDIR /tmp

# Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    yum -y install --enablerepo=remi,epel,remi-php74 php-devel php-pear && \
    pecl install -a xdebug

RUN echo [zend debugger] >> /etc/php.ini && \
    echo zend_extension=/usr/lib64/php/modules/xdebug.so >> /etc/php.ini && \
    echo xdebug.defaul_enable=1 >> /etc/php.ini && \
    echo xdebug.remote_enable=1 >> /etc/php.ini && \
    echo xdebug.remote_port=9000 >> /etc/php.ini && \
    echo xdebug.remote_handler=dbgp >> /etc/php.ini && \
    echo xdebug.remote_autostart=1 >> /etc/php.ini && \
    echo xdebug.remote_connect_back=1 >> /etc/php.ini

# ■ ログローテーション インストール
RUN  yum install -y logrotate
COPY ./conf/logrotate.conf /etc/logrotate.conf

# ■ Cornインストール
RUN  yum -y install cronie-noanacron
COPY ./conf/crontab /etc/crontab

RUN mv /usr/sbin/suexec /usr/sbin/suexec_

WORKDIR /var/www/html
COPY src/index.php /var/www/html/

# Supervisord の設定ファイルを Docker イメージ内に転送する
ADD ./conf/supervisord.conf /etc/supervisord.d/supervisord.ini

# Supervisord の設定ファイルを Docker イメージ内に転送する
ADD ./conf/supervisord.conf /etc/supervisord.d/supervisord.ini

# sshd の使うポートを公開する
EXPOSE 22 80

CMD ["/usr/bin/supervisord"]
