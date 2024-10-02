#!/bin/bash

docker run -p 6432:6432 -e CS_STATEMENT_HANDLER=mylittleproxy -v $(pwd)/cipherstash-proxy.toml:/etc/cipherstash-proxy/cipherstash-proxy.toml cipherstash/cipherstash-proxy:cipherstash-proxy-v0.0.25