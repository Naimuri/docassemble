FROM debian:stretch

RUN DEBIAN_FRONTEND=noninteractive bash -c 'echo -e "deb http://deb.debian.org/debian stretch main contrib\ndeb http://deb.debian.org/debian stretch-updates main\ndeb http://security.debian.org/debian-security stretch/updates main\ndeb http://ftp.debian.org/debian stretch-backports main" > /etc/apt/sources.list && \
    apt-get -y update'

RUN DEBIAN_FRONTEND=noninteractive bash -c " \
    until apt-get -q -y install \
    apt-utils \
    tzdata \
    python \
    python-dev \
    wget \
    unzip \
    git \
    locales \
    pandoc \
    texlive \
    texlive-latex-extra \
    texlive-font-utils \
    texlive-extra-utils \
    apache2 \
    postgresql \
    libapache2-modsecurity \
    libapache2-mod-wsgi \
    libapache2-mod-xsendfile \
    poppler-utils \
    libffi-dev \
    libffi6 \
    imagemagick \
    gcc \
    supervisor \
    libaudio-flac-header-perl \
    libaudio-musepack-perl \
    libmp3-tag-perl \
    libogg-vorbis-header-pureperl-perl \
    make \
    perl \
    vim-gnome \
    libvorbis-dev \
    libcddb-perl \
    libinline-perl \
    libcddb-get-perl \
    libmp3-tag-perl \
    libaudio-scan-perl \
    libaudio-flac-header-perl \
    libparallel-forkmanager-perl \
    libav-tools \
    autoconf \
    automake \
    libjpeg-dev \
    zlib1g-dev \
    libpq-dev \
    logrotate \
    cron \
    pdftk \
    libxml2 \
    libxslt1.1 \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    redis-server \
    rabbitmq-server \
    libtool \
    libtool-bin \
    pacpl \
    syslog-ng \
    rsync \
    curl \
    mktemp \
    dnsutils \
    tesseract-ocr \
    tesseract-ocr-dev \
    tesseract-ocr-afr \
    tesseract-ocr-ara \
    tesseract-ocr-aze \
    tesseract-ocr-bel \
    tesseract-ocr-ben \
    tesseract-ocr-bul \
    tesseract-ocr-cat \
    tesseract-ocr-ces \
    tesseract-ocr-chi-sim \
    tesseract-ocr-chi-tra \
    tesseract-ocr-chr \
    tesseract-ocr-dan \
    tesseract-ocr-deu \
    tesseract-ocr-deu-frak \
    tesseract-ocr-ell \
    tesseract-ocr-eng \
    tesseract-ocr-enm \
    tesseract-ocr-epo \
    tesseract-ocr-equ \
    tesseract-ocr-est \
    tesseract-ocr-eus \
    tesseract-ocr-fin \
    tesseract-ocr-fra \
    tesseract-ocr-frk \
    tesseract-ocr-frm \
    tesseract-ocr-glg \
    tesseract-ocr-grc \
    tesseract-ocr-heb \
    tesseract-ocr-hin \
    tesseract-ocr-hrv \
    tesseract-ocr-hun \
    tesseract-ocr-ind \
    tesseract-ocr-isl \
    tesseract-ocr-ita \
    tesseract-ocr-ita-old \
    tesseract-ocr-jpn \
    tesseract-ocr-kan \
    tesseract-ocr-kor \
    tesseract-ocr-lav \
    tesseract-ocr-lit \
    tesseract-ocr-mal \
    tesseract-ocr-mkd \
    tesseract-ocr-mlt \
    tesseract-ocr-msa \
    tesseract-ocr-nld \
    tesseract-ocr-nor \
    tesseract-ocr-osd \
    tesseract-ocr-pol \
    tesseract-ocr-por \
    tesseract-ocr-ron \
    tesseract-ocr-rus \
    tesseract-ocr-slk \
    tesseract-ocr-slk-frak \
    tesseract-ocr-slv \
    tesseract-ocr-spa \
    tesseract-ocr-spa-old \
    tesseract-ocr-sqi \
    tesseract-ocr-srp \
    tesseract-ocr-swa \
    tesseract-ocr-swe \
    tesseract-ocr-tam \
    tesseract-ocr-tel \
    tesseract-ocr-tgl \
    tesseract-ocr-tha \
    tesseract-ocr-tur \
    tesseract-ocr-ukr \
    tesseract-ocr-vie \
    build-essential \
    nodejs \
    exim4-daemon-heavy \
    libsvm3 \
    libsvm-dev \
    liblinear3 \
    liblinear-dev \
    libzbar-dev \
    cm-super \
    libgs-dev \
    ghostscript \
    default-libmysqlclient-dev \
    libgmp-dev \
    python-passlib \
    libsasl2-dev \
    libldap2-dev \
    ttf-mscorefonts-installer \
    fonts-ebgaramond-extra \
    ttf-liberation \
    fonts-liberation \
    qpdf; \
    do sleep 5; done; \
    apt-get -q -y install -t \
    stretch-backports \
    libreoffice; \
    wget http://http.us.debian.org/debian/pool/main/m/mod-wsgi/libapache2-mod-wsgi_4.3.0-1_amd64.deb && \
    dpkg -i libapache2-mod-wsgi_4.3.0-1_amd64.deb && \
    rm libapache2-mod-wsgi_4.3.0-1_amd64.deb"

RUN DEBIAN_FRONTEND=noninteractive TERM=xterm \
    cd /tmp && \
    wget https://github.com/jgm/pandoc/releases/download/2.5/pandoc-2.5-1-amd64.deb && \
    dpkg -i pandoc-2.5-1-amd64.deb && \
    rm pandoc-2.5-1-amd64.deb && \
    mkdir -p /etc/ssl/aura \
    /usr/share/aura/local \
    /usr/share/aura/certs \
    /usr/share/aura/backup \
    /usr/share/aura/config \
    /usr/share/aura/webapp \
    /usr/share/aura/files \
    /var/www/.pip \
    /var/www/.cache \
    /usr/share/aura/log \
    /tmp/aura \
    /usr/share/lua/5.1 \
    /var/www/html/log && \
    echo '{ "args": ["--no-sandbox"] }' > /var/www/puppeteer-config.json && \
    chown -R www-data.www-data /var/www && \
    chsh -s /bin/bash www-data && \
    update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10 && \
    wget -qO- https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get -y install nodejs && \
    npm install -g azure-storage-cmd && \
    npm install -g mermaid.cli


RUN DEBIAN_FRONTEND=noninteractive TERM=xterm \
    cd /usr/share/aura && \
    git clone https://github.com/letsencrypt/letsencrypt && \
    cd letsencrypt && \
    ./letsencrypt-auto --help && \
    echo "host   all   all  0.0.0.0/0   md5" >> /etc/postgresql/9.6/main/pg_hba.conf && \
    echo "listen_addresses = '*'" >> /etc/postgresql/9.6/main/postgresql.conf


COPY . /tmp/aura/

RUN DEBIAN_FRONTEND=noninteractive TERM=xterm \
    ln -s /var/mail/mail /var/mail/root && \
    cp /tmp/aura/aura_webapp/aura.wsgi /usr/share/aura/webapp/ && \
    cp /tmp/aura/Docker/*.sh /usr/share/aura/webapp/ && \
    cp /tmp/aura/Docker/VERSION /usr/share/aura/webapp/ && \
    cp /tmp/aura/Docker/pip.conf /usr/share/aura/local/ && \
    cp /tmp/aura/Docker/config/* /usr/share/aura/config/ && \
    cp /tmp/aura/Docker/cgi-bin/index.sh /usr/lib/cgi-bin/ && \
    cp /tmp/aura/Docker/syslog-ng.conf /usr/share/aura/webapp/syslog-ng.conf && \
    cp /tmp/aura/Docker/syslog-ng-docker.conf /usr/share/aura/webapp/syslog-ng-docker.conf && \
    cp /tmp/aura/Docker/aura-syslog-ng.conf /usr/share/aura/webapp/aura-syslog-ng.conf && \
    cp /tmp/aura/Docker/apache.logrotate /etc/logrotate.d/apache2 && \
    cp /tmp/aura/Docker/aura.logrotate /etc/logrotate.d/aura && \
    cp /tmp/aura/Docker/cron/aura-cron-monthly.sh /etc/cron.monthly/aura && \
    cp /tmp/aura/Docker/cron/aura-cron-weekly.sh /etc/cron.weekly/aura && \
    cp /tmp/aura/Docker/cron/aura-cron-daily.sh /etc/cron.daily/aura && \
    cp /tmp/aura/Docker/cron/aura-cron-hourly.sh /etc/cron.hourly/aura && \
    cp /tmp/aura/Docker/aura.conf /etc/apache2/conf-available/ && \
    cp /tmp/aura/Docker/aura-behindlb.conf /etc/apache2/conf-available/ && \
    cp /tmp/aura/Docker/aura-supervisor.conf /etc/supervisor/conf.d/aura.conf && \
    cp /tmp/aura/Docker/ssl/* /usr/share/aura/certs/ && \
    cp /tmp/aura/Docker/rabbitmq.config /etc/rabbitmq/ && \
    cp /tmp/aura/Docker/config/exim4-router /etc/exim4/conf.d/router/101_aura && \
    cp /tmp/aura/Docker/config/exim4-filter /etc/exim4/aura-filter && \
    cp /tmp/aura/Docker/config/exim4-main /etc/exim4/conf.d/main/01_aura && \
    cp /tmp/aura/Docker/config/exim4-acl /etc/exim4/conf.d/acl/29_aura && \
    cp /tmp/aura/Docker/config/exim4-update /etc/exim4/update-exim4.conf.conf && \
    cp /tmp/aura/Docker/config/validate.lua /etc/modsecurity/validate.lua && \
    cp /tmp/aura/Docker/config/verification.lua /usr/share/lua/5.1/verification.lua && \
    cp /tmp/aura/Docker/config/utilities.lua /usr/share/lua/5.1/utilities.lua && \
    update-exim4.conf && \
    bash -c "chown www-data.www-data /usr/share/aura/config && \
    chown www-data.www-data /usr/share/aura/config/config.yml.dist /usr/share/aura/webapp/aura.wsgi && \
    chown -R www-data.www-data /tmp/aura /usr/share/aura/local /usr/share/aura/log /usr/share/aura/files && \
    chmod ogu+r /usr/share/aura/config/config.yml.dist && \
    chmod 755 /etc/ssl/aura && \
    cd /tmp && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm -f get-pip.py && \
    pip install --upgrade \
    awscli \
    virtualenv"

USER www-data

RUN bash -c "cd /tmp && \
    virtualenv /usr/share/aura/local && \
    source /usr/share/aura/local/bin/activate && \
    pip install --upgrade pip && \
    pip install \
    3to2 \
    bcrypt \
    flask \
    flask-login \
    flask-mail \
    flask-sqlalchemy \
    flask-wtf \
    distutils2 \
    passlib \
    pycryptodome && \
    pip install --upgrade \
    'git+https://github.com/nekstrom/pyrtf-ng#egg=pyrtf-ng' \
    'git+https://github.com/euske/pdfminer.git' \
    simplekv==0.10.0 \
    /tmp/aura/aura \
    /tmp/aura/aura_base \
    /tmp/aura/aura_demo \
    /tmp/aura/aura_webapp"


USER root

RUN rm -rf /tmp/aura && \
    rm -f /etc/cron.daily/apt-compat && \
    mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf && \
    sed -i -e 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf && \
    sed -i '6 a secRuleScript "/etc/modsecurity/validate.lua" "deny"' /etc/modsecurity/modsecurity.conf && \
    sed -i '4 a SecRule REQUEST_URI "@beginsWith /apache_error.log" "phase:1,id:12701,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i '5 a SecRule REQUEST_URI "@beginsWith /apache_access.log" "phase:1,id:12702,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i '6 a SecRule REQUEST_URI "@beginsWith /aura.log" "phase:1,id:12703,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i '7 a SecRule REQUEST_URI "@beginsWith /worker.log" "phase:1,id:12704,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i '8 a SecRule REQUEST_URI "@beginsWith /assessment/config" "phase:1,id:12705,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i '9 a SecRule REQUEST_URI "@beginsWith /assessment/logfile/aura.log" "phase:1,id:12706,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i '10 a SecRule REQUEST_URI "@beginsWith /assessment/logfile/worker.log" "phase:1,id:12707,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i '11 a SecRule REQUEST_URI "@beginsWith /assessment/logfile/apache_access.log" "phase:1,id:12708,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i '12 a SecRule REQUEST_URI "@beginsWith /assessment/logfile/apache_error.log" "phase:1,id:12709,allow"' /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    sed -i -e 's/^\(daemonize\s*\)yes\s*$/\1no/g' -e 's/^bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf && \
    sed -i -e 's/#APACHE_ULIMIT_MAX_FILES/APACHE_ULIMIT_MAX_FILES/' -e 's/ulimit -n 65536/ulimit -n 8192/' /etc/apache2/envvars && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8 && \
    a2dismod ssl; \
    a2enmod wsgi; \
    a2enmod rewrite; \
    a2enmod xsendfile; \
    a2enmod proxy; \
    a2enmod proxy_http; \
    a2enmod proxy_wstunnel; \
    a2enmod headers; \
    a2enconf aura; \
    echo 'export TERM=xterm' >> /etc/bash.bashrc


EXPOSE 80 443 9001 514 25 465 8080 8081 5432 6379 4369 5671 5672 25672

ENV CONTAINERROLE="all" \
    LOCALE="en_US.UTF-8 \
    UTF-8" \
    TIMEZONE="America/New_York" \
    EC2="" \
    S3ENABLE="" \
    S3BUCKET="" \
    S3ACCESSKEY="" \
    S3SECRETACCESSKEY="" \
    DAHOSTNAME="" \
    USEHTTPS="" \
    USELETSENCRYPT="" \
    LETSENCRYPTEMAIL="" \
    DBHOST="" \
    LOGSERVER="" \
    REDIS="" \
    RABBITMQ=""


ENTRYPOINT ["/usr/share/aura/webapp/initialize.sh"]
