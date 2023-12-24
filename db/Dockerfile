FROM postgres:15.5-alpine

#COPY sql/ .
#COPY pg_hba.conf /var/lib/postgresql/data/pg_hba.conf

COPY sql/main.sql /docker-entrypoint-initdb.d/

#RUN /mainsql-gen.sh && cp main.sql /docker-entrypoint-initdb.d/

EXPOSE 5432


