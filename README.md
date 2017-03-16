# Ur/Web Regex

Client/server regular expresion support in Ur/Web

## Features

* untyped API for executing regular expressions represented as raw
  strings
* typeful API for building and executing well-formed regular
  expressions

## Usage examples

Please see the tests.

## Getting started

You will have to build the library and install it, see below.

### Third-party dependencies

You will need:

* Clang C++ compiler
* Boost.Regex library

On Ubuntu, you could install these via:

```
sudo apt-get install libboost-regex-dev clang
```

### Building

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

### Running tests

You will probably have to add `/usr/local/lib` to `ldconfig`
cache. This can be done as follows:

```
#!/bin/bash
sudo bash -c 'echo "/usr/local/lib" >>/etc/ld.so.conf.d/usr-local-lib.conf'
sudo ldconfig
```
