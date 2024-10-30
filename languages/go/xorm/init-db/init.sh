#!/bin/bash

psql -U $POSTGRES_USER -d postgres -f /app/scripts/db/create-db.sql
psql -U $POSTGRES_USER -d gotest -a -f /app/scripts/db/cipherstash-encrypt.sql