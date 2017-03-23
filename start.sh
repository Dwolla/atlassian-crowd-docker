#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

aws s3 cp ${DATABASE_CONFIG_OBJECT} ${CROWD_HOME}/crowduser.json
aws s3 cp ${CROWD_CONFIG_OBJECT} ${CROWD_HOME}/config.json

if aws s3 ls ${CROWD_SECRETS_OBJECT} > /dev/null; then
  aws s3 cp ${CROWD_SECRETS_OBJECT} ${CROWD_HOME}/config_secrets.json
else
  cat <<__CONFIG_SECRETS_END__ > ${CROWD_HOME}/config_secrets.json
{
  "application_password": ""
}
__CONFIG_SECRETS_END__
fi

# Set up JNDI resources in Tomcat root context
tmpl=$(cat /opt/context.xml.tmpl | sed 's_"_\\"_g')
printf "\"%s\"" "$tmpl" | jq -r -f /dev/stdin ${CROWD_HOME}/crowduser.json > ${CATALINA_HOME}/conf/Catalina/localhost/crowd.xml

tmpl=$(cat /opt/crowd.cfg.tmpl | sed 's_"_\\"_g')
printf "\"%s\"" "$tmpl" | jq -r -f /dev/stdin ${CROWD_HOME}/config.json > ${CROWD_HOME}/crowd.cfg.xml

cat <<__PROPERTIES_END__ | xargs -0 printf "\"%s\"" | jq -r -f /dev/stdin ${CROWD_HOME}/config_secrets.json > ${CROWD_HOME}/crowd.properties
session.lastvalidation=session.lastvalidation
session.tokenkey=session.tokenkey
crowd.server.url=https\\\://localhost:8443/crowd/services/
application.login.url=https\\\://${CROWD_SERVER_URL}/crowd
crowd.base.url=https\\\://${CROWD_SERVER_URL}/crowd/
application.name=crowd
http.timeout=30000
session.isauthenticated=session.isauthenticated
session.validationinterval=0
application.password=\(.application_password)
__PROPERTIES_END__

cat <<__CROWD_INIT_END__ > ${CROWD_INSTALL}/WEB-INF/classes/crowd-init.properties
crowd.home=${CROWD_HOME}
__CROWD_INIT_END__

openssl req -x509 \
    -newkey rsa:4096 \
    -keyout ${CATALINA_HOME}/conf/localhost-rsa-key.pem \
    -out ${CATALINA_HOME}/conf/localhost-rsa-cert.pem \
    -days 365 \
    -nodes \
    -subj "${CROWD_TLS_SUBJ}"

keytool -import \
    -alias crowd \
    -file $CATALINA_HOME/conf/localhost-rsa-cert.pem \
    -keystore $JAVA_HOME/lib/security/cacerts \
    -storepass changeit \
    -noprompt

exec ${CATALINA_HOME}/bin/catalina.sh $@
