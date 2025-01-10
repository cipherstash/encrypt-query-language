#!/bin/bash
#MISE description="Clean install of EQL"

set -euxo pipefail

connection_url=postgresql://${CS_DATABASE__USERNAME:-$USER}@localhost:$CS_DATABASE__PORT/$CS_DATABASE__NAME

# Uninstall
PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f release/cipherstash-encrypt-uninstall.sql

PGPASSWORD=$CS_DATABASE__PASSWORD psql $connection_url -f release/cipherstash-encrypt.sql
