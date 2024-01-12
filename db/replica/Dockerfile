FROM postgres:15.5-alpine

USER root

COPY ./replica-entrypoint.sh /entrypoint.sh

RUN mkdir -p /backup && \
    chown postgres -R /backup && \
    chmod +x /entrypoint.sh

USER postgres

ENTRYPOINT ["/entrypoint.sh"]
