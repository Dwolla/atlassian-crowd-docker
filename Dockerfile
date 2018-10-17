FROM blacklabelops/crowd:3.3.0

LABEL maintainer Dwolla Engineering <dev+crowd@dwolla.com>
LABEL org.label-schema.vcs-url="https://github.com/Dwolla/atlassian-crowd-docker"

EXPOSE 8443

RUN apk add --upgrade apk-tools && \
    apk add -U jq openssl python py-pip tomcat-native && \
    curl https://www.digicert.com/CACerts/GTECyberTrustGlobalRoot.crt | openssl x509 -inform der -outform pem -out /usr/local/share/ca-certificates/GTECyberTrustGlobalRoot.crt && \
    update-ca-certificates && \
    pip install --upgrade pip && \
    pip install awscli && \
    apk --purge -v del py-pip && \
    rm -rf /var/cache/apk/* /root/.cache/

COPY crowd.cfg.tmpl /opt/crowd.cfg.tmpl
COPY server.xml /opt/server.xml
COPY start.sh /opt/start.sh

ENTRYPOINT ["/opt/start.sh"]
