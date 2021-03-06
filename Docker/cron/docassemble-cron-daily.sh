#! /bin/bash

export DA_ROOT="${DA_ROOT:-/usr/share/docassemble}"
export DA_ACTIVATE="${DA_PYTHON:-${DA_ROOT}/local}/bin/activate"
export DA_CONFIG_FILE="${DA_CONFIG:-${DA_ROOT}/config/config.yml}"
export CONTAINERROLE=":${CONTAINERROLE:-all}:"
source /dev/stdin < <(su -c "source $DA_ACTIVATE && python -m docassemble.base.read_config $DA_CONFIG_FILE" www-data)

if [ "${S3ENABLE:-null}" == "null" ] && [ "${S3BUCKET:-null}" != "null" ]; then
    export S3ENABLE=true
fi

if [ "${S3ENABLE:-null}" == "true" ] && [ "${S3BUCKET:-null}" != "null" ] && [ "${S3ACCESSKEY:-null}" != "null" ] && [ "${S3SECRETACCESSKEY:-null}" != "null" ]; then
    export AWS_ACCESS_KEY_ID=$S3ACCESSKEY
    export AWS_SECRET_ACCESS_KEY=$S3SECRETACCESSKEY
fi

if [ "${AZUREENABLE:-null}" == "null" ] && [ "${AZUREACCOUNTNAME:-null}" != "null" ] && [ "${AZURECONTAINER:-null}" != "null" ]; then
    export AZUREENABLE=true
    blob-cmd add-account "${AZUREACCOUNTNAME}" "${AZUREACCOUNTKEY}"
fi

if [[ $CONTAINERROLE =~ .*:(all|cron):.* ]]; then
    ${DA_ROOT}/webapp/run-cron.sh cron_daily
fi

if [[ $CONTAINERROLE =~ .*:(all|web):.* ]]; then
    if [ "${USEHTTPS:-false}" == "true" ]; then
        if [ "${USELETSENCRYPT:-false}" == "true" ]; then
            if [ -f /etc/letsencrypt/da_using_lets_encrypt ]; then
                supervisorctl --serverurl http://localhost:9001 stop apache2
                cd ${DA_ROOT}/letsencrypt
                ./letsencrypt-auto renew
                /etc/init.d/apache2 stop
                supervisorctl --serverurl http://localhost:9001 start apache2
                if [ "${S3ENABLE:-false}" == "true" ]; then
                    cd /
                    if [ "${USELETSENCRYPT:-none}" != "none" ]; then
                        rm -f /tmp/letsencrypt.tar.gz
                        tar -zcf /tmp/letsencrypt.tar.gz etc/letsencrypt
                        aws s3 cp /tmp/letsencrypt.tar.gz 's3://'${S3BUCKET}/letsencrypt.tar.gz --quiet
                    fi
                    aws s3 sync /etc/apache2/sites-available/ 's3://'${S3BUCKET}/apache/ --quiet
                fi
                if [ "${AZUREENABLE:-false}" == "true" ]; then
                    blob-cmd add-account "${AZUREACCOUNTNAME}" "${AZUREACCOUNTKEY}"
                    cd /
                    if [ "${USELETSENCRYPT:-none}" != "none" ]; then
                        rm -f /tmp/letsencrypt.tar.gz
                        tar -zcf /tmp/letsencrypt.tar.gz etc/letsencrypt
                        blob-cmd -f cp /tmp/letsencrypt.tar.gz 'blob://'${AZUREACCOUNTNAME}'/'${AZURECONTAINER}'/letsencrypt.tar.gz'
                    fi
                    for the_file in $(find /etc/apache2/sites-available/ -type f); do
                        target_file=$(basename $the_file)
                        blob-cmd -f cp "$the_file" 'blob://'${AZUREACCOUNTNAME}'/'${AZURECONTAINER}'/apache/'"$target_file"
                    done
                fi
                if [ ! -f /etc/ssl/docassemble/exim.crt ] && [ ! -f /etc/ssl/docassemble/exim.key ]; then
                    cp /etc/letsencrypt/live/${DAHOSTNAME}/fullchain.pem /etc/exim4/exim.crt
                    cp /etc/letsencrypt/live/${DAHOSTNAME}/privkey.pem /etc/exim4/exim.key
                    chown root.Debian-exim /etc/exim4/exim.crt
                    chown root.Debian-exim /etc/exim4/exim.key
                    chmod 640 /etc/exim4/exim.crt
                    chmod 640 /etc/exim4/exim.key
                    supervisorctl --serverurl http://localhost:9001 stop exim4
                    supervisorctl --serverurl http://localhost:9001 start exim4
                fi
            fi
        fi
    fi
fi

MONTHDAY=$(date +%m-%d)
BACKUPDIR=${DA_ROOT}/backup/$MONTHDAY
rm -rf $BACKUPDIR
mkdir -p $BACKUPDIR
if [[ $CONTAINERROLE =~ .*:(all|web|celery|log|cron):.* ]]; then
    rsync -au ${DA_ROOT}/files $BACKUPDIR/
    rsync -au ${DA_ROOT}/config $BACKUPDIR/
    rsync -au --exclude '*/worker.log*' ${DA_ROOT}/log $BACKUPDIR/
fi

if [[ $CONTAINERROLE =~ .*:(all|sql):.* ]]; then
    PGBACKUPDIR=$(mktemp -d)
    chown postgres.postgres "$PGBACKUPDIR"
    su postgres -c 'psql -Atc "SELECT datname FROM pg_database" postgres' | grep -v -e template -e postgres | awk -v backupdir="$PGBACKUPDIR" '{print "cd /tmp; su postgres -c \"pg_dump -F c -f " backupdir "/" $1 " " $1 "\""}' | bash
    rsync -au "$PGBACKUPDIR/" $BACKUPDIR/postgres
    if [ "${S3ENABLE:-false}" == "true" ]; then
        aws s3 sync "$PGBACKUPDIR/" s3://${S3BUCKET}/postgres/
    fi
    if [ "${AZUREENABLE:-false}" == "true" ]; then
        for the_file in $(find "$PGBACKUPDIR/" -type f); do
            target_file=$(basename $the_file)
            blob-cmd -f cp "$the_file" 'blob://'${AZUREACCOUNTNAME}'/'${AZURECONTAINER}"/postgres/$target_file"
        done
    fi
    rm -rf "$PGBACKUPDIR"
fi
if [ "${AZUREENABLE:-false}" == "false" ]; then
    rm -rf $(find ${DA_ROOT}/backup -maxdepth 1 -path '*[0-9][0-9]-[0-9][0-9]' -a -type 'd' -a -mtime +${DABACKUPDAYS} -print)
fi
if [ "${S3ENABLE:-false}" == "true" ]; then
    if [ "${EC2:-false}" == "true" ]; then
        export LOCAL_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
    else
        export LOCAL_HOSTNAME=$(hostname --fqdn)
    fi
    aws s3 sync ${DA_ROOT}/backup/ s3://${S3BUCKET}/backup/${LOCAL_HOSTNAME}/
fi
if [ "${AZUREENABLE:-false}" == "true" ]; then
    if [ "${EC2:-false}" == "true" ]; then
        export LOCAL_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
    else
        export LOCAL_HOSTNAME=$(hostname --fqdn)
    fi
    for the_file in $(find ${DA_ROOT}/backup/ -type f | cut -c 31-); do
        blob-cmd -f cp "${DA_ROOT}/backup/$the_file" 'blob://'${AZUREACCOUNTNAME}'/'${AZURECONTAINER}'/backup/'${LOCAL_HOSTNAME}'/'${the_file}
    done
    for the_dir in $(find ${DA_ROOT}/backup -maxdepth 1 -path '*[0-9][0-9]-[0-9][0-9]' -a -type 'd' -a -mtime +${DABACKUPDAYS} -print | cut -c 31-); do
        for the_file in $(find "${DA_ROOT}/backup/${the_dir}" -type f | cut -c 31-); do
            blob-cmd -f rm 'blob://'${AZUREACCOUNTNAME}'/'${AZURECONTAINER}'/backup/'${LOCAL_HOSTNAME}'/'$($the_file)
        done
        rm -rf ${DA_ROOT}/backup/$the_dir
    done
fi

if [ "${AZUREENABLE:-false}" == "true" ] || [ "${S3ENABLE:-false}" == "true" ]; then
    for old_dir in $(find /tmp/files -type d -mmin +1440 -path "/tmp/files/*"); do
        rm -rf "$old_dir"
    done
fi
