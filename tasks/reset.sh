#!/bin/bash
#MISE description="Uninstall and install EQL to local postgres"

set -euxo pipefail

connection_url=postgresql://${CS_DATABASE__USERNAME:-$USER}:${CS_DATABASE__PASSWORD}@localhost:$CS_DATABASE__PORT/$CS_DATABASE__NAME

# Uninstall
psql ${connection_url} -f release/cipherstash-encrypt-uninstall.sql

# Install
psql ${connection_url} -f release/cipherstash-encrypt.sql
