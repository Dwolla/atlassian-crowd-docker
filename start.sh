#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
aws s3 cp ${DATABASE_CONFIG_OBJECT} ${CROWD_HOME}/crowduser.json
aws s3 cp ${CROWD_CONFIG_OBJECT} ${CROWD_HOME}/config.json

# Exports for docker-entrypoint/launch.sh
echo 'export CROWDDB_URL=mysql://$(jq -r '.crowd.host' < ${CROWD_HOME}/crowduser.json):$(jq -r '.crowd.port' < ${CROWD_HOME}/crowduser.json)/$(jq -r '.crowd.database' < ${CROWD_HOME}/crowduser.json)' >> /home/crowd/common.sh
echo 'export CROWDDB_USER=$(jq -r '.crowd.user' < ${CROWD_HOME}/crowduser.json)' >> /home/crowd/common.sh
echo 'export CROWDDB_PASSWORD=$(jq -r '.crowd.password' < ${CROWD_HOME}/crowduser.json)' >> /home/crowd/common.sh

mkdir -p ${CROWD_HOME}/shared
tmpl=$(cat /opt/crowd.cfg.tmpl | sed 's_"_\\"_g')
printf "\"%s\"" "$tmpl" | jq -r -f /dev/stdin ${CROWD_HOME}/config.json > ${CROWD_HOME}/shared/crowd.cfg.xml
chown -R crowd ${CROWD_HOME}/shared

mkdir -p /opt/crowd/apache-tomcat/conf/
mv /opt/server.xml /opt/crowd/apache-tomcat/conf/

# Add Redirect from / to /crowd/
mkdir -p /opt/crowd/apache-tomcat/webapps/ROOT
echo '<% response.sendRedirect("/crowd/"); %>' > /opt/crowd/apache-tomcat/webapps/ROOT/index.jsp
chown -R crowd:crowd /opt/crowd/

sed -i 's/8095/8443/g' /opt/crowd/build.properties

openssl req -x509 \
    -newkey rsa:4096 \
    -keyout /opt/crowd/apache-tomcat/conf/localhost-rsa-key.pem \
    -out /opt/crowd/apache-tomcat/conf/localhost-rsa-cert.pem \
    -days 365 \
    -nodes \
    -subj "${CROWD_TLS_SUBJ}"

keytool -import \
    -alias crowd \
    -file /opt/crowd/apache-tomcat/conf/localhost-rsa-cert.pem \
    -keystore $JAVA_HOME/jre/lib/security/cacerts \
    -storepass changeit \
    -noprompt

exec /bin/tini -- /home/crowd/docker-entrypoint.sh crowd
