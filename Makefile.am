# Copyright 2015 the Massachusetts Institute of Technology
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy of
# the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

ACLOCAL_AMFLAGS = -I m4

CPPFLAGS = \
	-Wall \
	-D_FORTIFY_SOURCE=2

CXXFLAGS = \
	-std=c++11 \
	-ftrapv \
	-fstack-protector-strong --param=ssp-buffer-size=4 \
	-fPIE \
	-O2 \
	-ffunction-sections -fdata-sections

CXXFLAGS += \
	-Weverything \
	-Wno-c++98-compat \
	-Wno-padded \
	-Wno-switch-enum

LDFLAGS = \
	-Wl,-Bsymbolic-functions \
	-fPIE -pie \
	-Wl,-z,now \
	-Wl,-z,relro \
	-Wl,--hash-style=gnu \
	-Wl,--no-copy-dt-needed-entries \
	-Wl,--as-needed

lib_LTLIBRARIES = liburweb_regex.la

liburweb_regex_la_SOURCES = src/regex__FFI.cc
liburweb_regex_la_DATA = \
	src/lib.urp \
	src/regex__FFI.h \
	src/regex__FFI.urs \
	src/regex.urs \
	src/regex.ur

liburweb_regex_la_LIBADD = -lurweb
liburweb_regex_la_LDFLAGS = \
	-export-symbols-regex '^uw_Regex_'

liburweb_regex_ladir = $(datadir)/urweb/ur/regex

EXTRA_DIST = \
	LICENSE \
	$(liburweb_regex_la_DATA)
