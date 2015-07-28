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

AC_INIT([urweb-regex], [1.0.0], [bbaren@mit.edu])
AM_INIT_AUTOMAKE([no-dist-gzip dist-xz foreign subdir-objects])
LT_INIT

AC_CONFIG_MACRO_DIR([m4])

AC_CONFIG_SRCDIR([config.h.in])
AC_CONFIG_HEADERS([config.h])

AC_PROG_CXX([clang++])
AX_CXX_COMPILE_STDCXX_11([noext], [mandatory])

AX_BOOST_BASE([1.48.0],
  [],
  [AC_MSG_FAILURE([Boost is required])])

AC_CHECK_HEADERS([urweb/urweb_cpp.h],
  [],
  [AC_MSG_FAILURE([Ur/Web headers are required])])
save_LIBS=$LIBS
LIBS="$LIBS -lurweb"
AC_LINK_IFELSE([AC_LANG_CALL(
                  [int uw_init_client_data;
                   int uw_copy_client_data;
                   int uw_global_custom;
                   int uw_do_expunge;
                   int uw_post_expunge;
                   int uw_free_client_data;],
                  [uw_error])],
  [],
  [AC_MSG_FAILURE([could not link with -lurweb])])
LIBS=$save_LIBS

AC_OUTPUT([Makefile])
