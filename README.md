# Getting started

`#!/bin/bash
aclocal
autoheader
libtoolize --force --copy
automake --add-missing --copy --foreign
autoconf
`

Then do the usual `./configure && make && sudo make install`

`sudo apt-get install libboost-regex-dev clang`
