// Copyright (C) 2015 the Massachusetts Institute of Technology
// Copyright (C) 2015 Benjamin Barenblat
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.

#include "src/regex__FFI.h"

#include <regex>  // NOLINT(build/c++11)
#include <stdexcept>
#include <vector>

#include <boost/numeric/conversion/cast.hpp>  // NOLINT(build/include_order)
extern "C" {
#include <urweb/urweb_cpp.h>  // NOLINT(build/include_order)
}

#include "./config.h"

namespace {

using Int = uw_Basis_int;
using Substring = uw_Regex__FFI_substring_t;
using SubstringList = uw_Regex__FFI_substring_list_t;

// Asserts a condition without crashing or releasing information about where the
// error occurred.  This function is essential for web programming, where an
// attacker should not be able to bring down the app by causing an assertion
// failure.
void Assert(uw_context* const context, const bool condition,
            const failure_kind action, const char* const message) {
  if (!condition) {
    uw_error(context, action, message);
  }
}

void Assert(uw_context* const context, const bool condition,
            const char* const message) {
  Assert(context, condition, FATAL, message);
}

// Bounds-checked numeric type conversion
template <typename Target, typename Source>
Target Number(uw_context* const context, Source arg) {
  try {
    return boost::numeric_cast<Target>(arg);
  } catch (const boost::numeric::bad_numeric_cast& e) {
    uw_error(context, FATAL, "regex: %s", e.what());
  }
}

// Compiles a regular expression.
std::regex Compile(uw_context* const context, const char needle_string[]) {
  std::regex needle;
  try {
    needle.assign(needle_string, std::regex_constants::ECMAScript);
  } catch (const std::regex_error& e) {
    switch (e.code()) {
      case std::regex_constants::error_space:
      case std::regex_constants::error_stack:
        // We ran out of memory.
        uw_error(context, BOUNDED_RETRY, "regex: compilation failed: %s",
                 e.what());
      default:
        uw_error(context, FATAL, "regex: compilation failed: %s", e.what());
    }
  }
  return needle;
}

// Treats 'list' as a 'std::vector<Substring>*' and 'delete's it.
void DeleteGroupList(void* list, [[gnu::unused]] const int will_retry) {
  delete reinterpret_cast<std::vector<Substring>*>(list);
}

}  // namespace

Int uw_Regex__FFI_substring_start(uw_context* const context,
                                  const Substring substring) {
  return Number<Int>(context, substring.start);
}

Int uw_Regex__FFI_substring_length(uw_context* const context,
                                   const Substring substring) {
  return Number<Int>(context, substring.length);
}

Int uw_Regex__FFI_substring_list_length(uw_context* const context,
                                        const SubstringList list) {
  return Number<Int>(
      context, reinterpret_cast<const std::vector<Substring>*>(list)->size());
}

Substring uw_Regex__FFI_substring_list_get(uw_context* const context,
                                           const SubstringList list,
                                           const Int index_int) {
  const auto index = Number<std::size_t>(context, index_int);
  try {
    return reinterpret_cast<const std::vector<Substring>*>(list)->at(index);
  } catch (const std::out_of_range& e) {
    uw_error(context, FATAL, "regex: index out of range", e.what());
  }
}

SubstringList uw_Regex__FFI_do_match(uw_context* const context,
                                     const uw_Basis_string needle,
                                     const uw_Basis_string haystack) {
  // Perform the match.
  std::cmatch match_results;
  std::regex_search(haystack, match_results, Compile(context, needle));
  Assert(context, match_results.ready(), "regex: search failed");
  // Marshal the results into the form Ur expects.
  auto* const result = new std::vector<Substring>;
  Assert(context, uw_register_transactional(context, result, nullptr, nullptr,
                                            DeleteGroupList) == 0,
         "regex: could not register DeleteGroupList finalizer");
  for (std::size_t i = 0; i < match_results.size(); i++) {
    result->emplace_back(
        Substring{Number<long>(context, match_results.position(i)),
                  Number<long>(context, match_results.length(i))});
  }
  return result;
}
