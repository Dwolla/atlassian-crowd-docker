# Atlassian Crowd Docker Image

[![](https://images.microbadger.com/badges/image/dwolla/atlassian-crowd.svg)](https://microbadger.com/images/dwolla/atlassian-crowd)
[![license](https://img.shields.io/github/license/dwolla/atlassian-crowd-docker.svg?style=flat-square)](https://github.com/Dwolla/atlassian-crowd-docker/blob/master/LICENSE.md)

Docker image with Atlassian Crowd, running on OpenJDK 8 / Alpine Linux with MySQL drivers.

We use a fork of https://github.com/blacklabelops/crowd as our base image to add specific configurations - mainly enabling SSL on port 8443 and redirecting / to /crowd/ through tomcat.  This docker image builds off that and puts configuration specific data in the correct place to allow for an automated deployment of crowd.

## Required Environment Variables

### `DATABASE_CONFIG_OBJECT`

Path to an S3 object (e.g. `s3://bucket/object.json`) structured as follows:

```
{
  "crowd": {
    "user": "username",
    "password": "password",
    "host": "mysql.database.hostname",
    "port": "3306",
    "database": "crowd"
  }
}
```

The credentials will be used by the upstream's base image [`launch.sh`](https://github.com/blacklabelops/crowd/blob/master/imagescripts/launch.sh) to create a JNDI resource at `jdbc/CrowdDS`

### `CROWD_CONFIG_OBJECT`

Path to an S3 object structured as follows:

```
{
  "crowdServerId": "B9AN-B9AN-B9AN-B9AN",
  "license": "AAABGQ0ODAoPeNpdkF1LwzAUhu/plus-some-more-stuff"
}
```

Both of these values can be found in [Atlassian licensing](http://my.atlassian.com/products/index).

### `CROWD_SERVER_URL`

The URL to your Crowd instance, once it’s up and running.

### `CATALINA_OPTS`

Give your Crowd instance more memory by setting `CATALINA_OPTS` to e.g. `-Xms512m -Xmx512m`.

### `CROWD_TLS_SUBJ`

The TLS subject for the self-signed certificate generated by the startup script. For example,

```
/C=US/ST=Iowa/L=Des Moines/O=Dwolla/CN=localhost/emailAddress=your-email-address@localhost"
```
