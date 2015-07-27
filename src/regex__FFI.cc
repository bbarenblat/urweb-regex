// Copyright (C) 2015 the Massachusetts Institute of Technology
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

#include "regex__FFI.h"

#include <regex.h>

#include <cstring>
#include <limits>
#include <regex>

extern "C" {
#include <urweb/urweb_cpp.h>
}

#include "config.h"

namespace {

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

void Assert(uw_context* const context,
            const bool condition, const char* const message) {
  Assert(context, condition, FATAL, message);
}

void DeleteRegex(void* regex, [[gnu::unused]] const int _will_retry) {
  delete reinterpret_cast<std::regex*>(regex);
}

void DeleteMatchResults(void* match_result,
                        [[gnu::unused]] const int _will_retry) {
  delete reinterpret_cast<std::cmatch*>(match_result);
}

// Bounds-checked numeric type conversion
template<typename T, typename U>
U Number(uw_context* const context, const T input) {
  Assert(context, input <= std::numeric_limits<U>::max(),
         "regex: detected overflow during numeric conversion");
  if (std::numeric_limits<T>::is_signed == std::numeric_limits<U>::is_signed) {
    Assert(context, std::numeric_limits<U>::lowest() <= input,
           "regex: detected underflow during numeric conversion");
  } else if (std::numeric_limits<T>::is_signed) {
    Assert(context, 0 <= input,
           "regex: detected underflow during numeric conversion");
  }
  return static_cast<U>(input);
}

}  // namespace

uw_Basis_bool uw_Regex__FFI_succeeded([[gnu::unused]] uw_context* const context,
                                      const uw_Regex__FFI_match match) {
  if (reinterpret_cast<std::cmatch*>(match.result)->empty()) {
    return uw_Basis_False;
  } else {
    return uw_Basis_True;
  }
}

uw_Basis_int uw_Regex__FFI_n_subexpression_matches(
    uw_context* const context,
    const uw_Regex__FFI_match match) {
  const std::cmatch::size_type n_matches =
      reinterpret_cast<std::cmatch*>(match.result)->size();
  if (n_matches == 0) {
    // Nothing got matched.
    return 0;
  } else {
    // At least one match occurred.  Compute the number of parenthesized
    // subexpressions that got matched, and return it.
    return Number<std::cmatch::size_type, uw_Basis_int>(context, n_matches) - 1;
  }
}

uw_Basis_string uw_Regex__FFI_subexpression_match(
    uw_context* const context,
    const uw_Regex__FFI_match match, 
    const uw_Basis_int match_index_signed) {
  const std::cmatch* const match_result =
      reinterpret_cast<std::cmatch*>(match.result);
  const std::size_t match_index =
      Number<uw_Basis_int, std::size_t>(context, match_index_signed);
  Assert(context, match_index < match_result->size(),
         "regex: match does not exist");
  const auto matched_substring = (*match_result)[match_index + 1];
  // Save the matched substring.
  const std::size_t result_length =
      Number<std::csub_match::difference_type, std::size_t>(
          context,
          matched_substring.length());
  uw_Basis_string result =
      reinterpret_cast<uw_Basis_string>(
          uw_malloc(context, result_length + 1));
  std::strcpy(result, matched_substring.str().c_str());
  return result;
}

uw_Regex__FFI_regex uw_Regex__FFI_compile(uw_context* const context,
                                          const uw_Basis_bool case_sensitive,
                                          const uw_Basis_string input) {
  // We'd like to stack-allocate the result--or, at least, to allocate it with
  // uw_malloc.  Unfortunately, neither of those will work, because we need to
  // run a finalizer on it, and Ur finalizers can only reference addresses that
  // are not managed by Ur.
  auto* result = new std::regex;
  Assert(context,
         uw_register_transactional(context, result,
                                   nullptr, nullptr, DeleteRegex) == 0,
         "regex: could not register DeleteRegex finalizer");
  auto flags = std::regex_constants::extended; 
  if (!case_sensitive) {
    flags |= std::regex_constants::icase;
  }
  try {
    result->assign(input, flags);
  } catch (const std::regex_error& e) {
    switch (e.code()) {
      case std::regex_constants::error_space:
      case std::regex_constants::error_stack:
        // We ran out of memory.
        uw_error(context, BOUNDED_RETRY,
                 "regex: compilation failed: %s", e.what());
      default:
        uw_error(context, FATAL,
                 "regex: compilation failed: %s", e.what());
    }
  }
  return result;
}

uw_Regex__FFI_match uw_Regex__FFI_do_match(uw_context* const context,
                                           const uw_Regex__FFI_regex needle,
                                           const uw_Basis_string haystack) {
  uw_Regex__FFI_match result;
  // Make a duplicate of the string to match against, so if it goes out of
  // scope in the calling Ur code, we still have it.
  result.haystack =
      reinterpret_cast<char*>(uw_malloc(context, std::strlen(haystack)));
  std::strcpy(result.haystack, haystack);
  // Allocate to store the match information.
  auto* match_results = new std::cmatch;
  Assert(context,
         uw_register_transactional(context, match_results,
                                   nullptr, nullptr, DeleteMatchResults) == 0,
         "regex: could not register DeleteMatchResults finalizer");
  result.result = match_results;
  // Execute the regex on the saved haystack, not the original one.
  std::regex_search(result.haystack, *match_results,
                    *reinterpret_cast<std::regex*>(needle));
  return result;
}
