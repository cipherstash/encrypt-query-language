FROM curlimages/curl:7.85.0 as fetch-eql
WORKDIR /out
RUN  curl -sLo /out/cipherstash-encrypt.sql https://github.com/cipherstash/encrypt-query-language/releases/download/eql-0.4.0/cipherstash-encrypt.sql

FROM postgres:16 as db
WORKDIR /app
COPY init.sh /docker-entrypoint-initdb.d
COPY create-db.sql /app/scripts/db/create-db.sql
COPY --from=fetch-eql /out/cipherstash-encrypt.sql /app/scripts/db/cipherstash-encrypt.sql
