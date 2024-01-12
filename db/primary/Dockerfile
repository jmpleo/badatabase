FROM postgres:15.5-alpine

COPY sql /sql
COPY ssl /ssl

USER root
RUN /sql/sqlgen.sh /sql /docker-entrypoint-initdb.d && \
    chown postgres -R /ssl

USER postgres

