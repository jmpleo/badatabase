FROM postgres:15.5-alpine

COPY . .
#COPY pg_hba.conf /var/lib/postgresql/data/pg_hba.conf

RUN /mainsql-gen.sh && cp main.sql /docker-entrypoint-initdb.d/

EXPOSE 5432


