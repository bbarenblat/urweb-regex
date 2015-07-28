/* Copyright (C) 2015 the Massachusetts Institute of Technology

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License. */

#ifndef URWEB_REGEX__FFI_H_  /* NOLINT(build/header_guard) */
#define URWEB_REGEX__FFI_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

#include <urweb/urweb_cpp.h>

typedef void* uw_Regex__FFI_regex;

typedef struct {
  char* haystack;
  void* result;
} uw_Regex__FFI_match;

uw_Basis_bool uw_Regex__FFI_succeeded(struct uw_context*,
                                      const uw_Regex__FFI_match);

uw_Basis_int uw_Regex__FFI_n_subexpression_matches(struct uw_context*,
                                                   const uw_Regex__FFI_match);

uw_Basis_string uw_Regex__FFI_subexpression_match(struct uw_context*,
                                                  const uw_Regex__FFI_match,
                                                  const uw_Basis_int);

uw_Regex__FFI_regex uw_Regex__FFI_compile(struct uw_context*,
                                          const uw_Basis_bool,
                                          const uw_Basis_string);

uw_Regex__FFI_match uw_Regex__FFI_do_match(struct uw_context*,
                                           const uw_Regex__FFI_regex,
                                           const uw_Basis_string);

#ifdef __cplusplus
}
#endif

#endif  /* URWEB_REGEX__FFI_H_ */  /* NOLINT(build/header_guard) */
