#!/usr/bin/env sh

swift run bench -c release -Xswiftc -O -Xswiftc -whole-module-optimization
