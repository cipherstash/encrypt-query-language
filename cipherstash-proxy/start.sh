#!/bin/bash

# The version is hard coded as we are in active development of some of the EQL features
docker run -p 6432:6432 -e CS_STATEMENT_HANDLER=mylittleproxy -e LOG_LEVEL=debug -v $(pwd)/cipherstash-proxy.toml:/etc/cipherstash-proxy/cipherstash-proxy.toml cipherstash/cipherstash-proxy:cipherstash-proxy-v0.1.0