#!/bin/bash

cd "`dirname "$0"`"

if [ "$1" = "" ]; then
    echo "Usage: $0 <aspace backend URL>"
    exit
fi

rm -rf output
java -cp 'lib/*' org.jruby.Main --1.9 simulator.rb output ${1+"$@"}
