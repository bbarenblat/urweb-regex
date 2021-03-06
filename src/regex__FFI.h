/* Copyright (C) 2015 the Massachusetts Institute of Technology
Copyright (C) 2015 Benjamin Barenblat

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License. */

/* clang-format off */
#ifndef URWEB_REGEX__FFI_H_  /* NOLINT(build/header_guard) */
#define URWEB_REGEX__FFI_H_
/* clang-format on */

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

#include <urweb/urweb_cpp.h>

typedef struct {
  long start;
  long length;
} uw_Regex__FFI_substring_t;

typedef void* uw_Regex__FFI_substring_list_t;

uw_Basis_int uw_Regex__FFI_substring_start(struct uw_context*,
                                           const uw_Regex__FFI_substring_t);

uw_Basis_int uw_Regex__FFI_substring_length(struct uw_context*,
                                            const uw_Regex__FFI_substring_t);

uw_Basis_int uw_Regex__FFI_substring_list_length(
    struct uw_context*, const uw_Regex__FFI_substring_list_t);

uw_Regex__FFI_substring_t uw_Regex__FFI_substring_list_get(
    struct uw_context*, const uw_Regex__FFI_substring_list_t,
    const uw_Basis_int);

uw_Regex__FFI_substring_list_t uw_Regex__FFI_do_match(struct uw_context*,
                                                      const uw_Basis_string,
                                                      const uw_Basis_string);

#ifdef __cplusplus
}
#endif

/* clang-format off */
#endif  /* URWEB_REGEX__FFI_H_ */  /* NOLINT(build/header_guard) */
/* clang-format on */
