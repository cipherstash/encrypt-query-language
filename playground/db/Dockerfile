FROM curlimages/curl:7.85.0 as fetch-eql
WORKDIR /out
RUN  curl -sLo /out/cipherstash-encrypt.sql https://github.com/cipherstash/encrypt-query-language/releases/download/eql-0.4.2/cipherstash-encrypt.sql

FROM postgres:16.2-bookworm as db
WORKDIR /app
COPY init.sh /docker-entrypoint-initdb.d
COPY --from=fetch-eql /out/cipherstash-encrypt.sql /app/scripts/db/cipherstash-encrypt.sql
