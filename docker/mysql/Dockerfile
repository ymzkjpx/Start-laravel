FROM mysql:8.0.28

RUN apt-get update \
&& apt-get -y install locales --no-install-recommends \
&& rm -rf /var/lib/apt/lists/*

RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8

ADD ./my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 644 /etc/mysql/conf.d/my.cnf
