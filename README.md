# Getting started

## Third-party dependencies

You will need:

* Clang C++ compiler
* Boost.Regex library

On Ubuntu, you could install these via:

```
sudo apt-get install libboost-regex-dev clang
```

## Building

Pre-build steps are due to usage of `autoconf` etc.

```
#!/bin/bash
aclocal
autoheader
libtoolize --force --copy
automake --add-missing --copy --foreign
autoconf
```

Then do the usual `./configure && make && sudo make install`
