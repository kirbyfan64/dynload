#!/bin/sh

ret=0

run() {
    echo "+ $@"
    eval "$@" || ret=1
}


run dartanalyzer lib/dynload.dart tst/cb.dart
run dart tst/tst.dart
exit $ret
