FROM postgres:15.5-alpine3.19

COPY sql /sql
COPY ssl /ssl

USER root

RUN apk update && \
    apk add --no-cache krb5 krb5-libs && \
    /sql/sqlgen.sh /sql /docker-entrypoint-initdb.d && \
    chown postgres -R /ssl

USER postgres

