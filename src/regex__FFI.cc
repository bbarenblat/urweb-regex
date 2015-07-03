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

#include <sys/types.h>
#include <regex.h>

#include <cstring>

extern "C" {
#include <urweb/urweb_cpp.h>
}

#include "config.h"

namespace {

using Regex = uw_Regex__FFI_regex;
using Match = uw_Regex__FFI_match;

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

void FinalizeRegex(void* regex, [[gnu::unused]] const int _will_retry) {
  regfree(reinterpret_cast<regex_t*>(regex));
}

void DeleteRegex(void* regex, [[gnu::unused]] const int _will_retry) {
  delete reinterpret_cast<regex_t*>(regex);
}

}  // namespace

uw_Basis_bool uw_Regex__FFI_succeeded(
    [[gnu::unused]] struct uw_context* _context,
    const Match match) {
  return match.succeeded ? uw_Basis_True : uw_Basis_False;
}

uw_Basis_int uw_Regex__FFI_n_subexpression_matches(
    [[gnu::unused]] struct uw_context* _context,
    const Match match) {
  return match.n_matches;
}

uw_Basis_string uw_Regex__FFI_subexpression_match(
    struct uw_context* context,
    const Match match,
    const uw_Basis_int match_index) {
  Assert(context, match.matches[match_index].rm_so != -1,
         "regex: match does not exist");
  // Locate the substring in the string to match aginst.
  const char* const substring_start =
      match.haystack + match.matches[match_index].rm_so;
  // Copy it into its own buffer so we can properly null-terminate it.
  const std::size_t substring_length =
      static_cast<std::size_t>(match.matches[match_index].rm_eo
                               - match.matches[match_index].rm_so);
  uw_Basis_string result = reinterpret_cast<uw_Basis_string>(
      uw_malloc(context, substring_length + 1));
  std::memcpy(result, substring_start, substring_length);
  result[substring_length] = '\0';
  return result;
}

Regex uw_Regex__FFI_compile(uw_context* const context,
                            const uw_Basis_bool case_sensitive,
                            const uw_Basis_string input) {
  Regex result;
  result.text = input;
  // We'd like to stack-allocate the compiled field of the Regex struct--or, at
  // least, to allocate it with uw_malloc.  Unfortunately, neither of those will
  // work, because we need to be able to run a finalizer on it, and Ur
  // finalizers can only reference addresses that are not managed by Ur.
  result.compiled = new regex_t;
  Assert(context,
         uw_register_transactional(context, result.compiled,
                                   nullptr, nullptr, DeleteRegex) == 0,
         "regex: could not register DeleteRegex finalizer");
  // Compile the regex.
  const auto flags = REG_EXTENDED | (case_sensitive ? 0 : REG_ICASE);
  switch (const auto regcomp_error = regcomp(result.compiled, input, flags)) {
    case 0:
      // Everything worked perfectly.
      break;
    case REG_ESPACE:
      // We ran out of memory.
      uw_error(context, BOUNDED_RETRY, "regex: could not allocate");
    default:
      // Something else happened.  Generate a nice message for the user.
      const auto message_size =
          regerror(regcomp_error, result.compiled, nullptr, 0);
      char* const message =
          reinterpret_cast<char*>(uw_malloc(context, message_size));
      Assert(context,
             regerror(regcomp_error, result.compiled, message,
                      message_size) == message_size,
             "regex: compilation failed, but error message could not be"
             " generated");
      uw_error(context, FATAL, "regex: compilation failed: %s", message);
  }
  Assert(context,
         uw_register_transactional(context, result.compiled,
                                   nullptr, nullptr, FinalizeRegex) == 0,
         "regex: could not register FinalizeRegex finalizer");
  // Give the caller the regex.
  return result;
}

Match uw_Regex__FFI_do_match(uw_context* const context, const Regex needle,
                             const uw_Basis_string haystack) {
  Match result;
  // Make a duplicate of the string to match against, so if it goes out of scope
  // in the calling Ur code, we still have it.  TODO(bbaren): Is this necessary?
  result.haystack =
      reinterpret_cast<uw_Basis_string>(
          uw_malloc(context, std::strlen(haystack)));
  std::strcpy(result.haystack, haystack);
  // Figure out how many groups we could have so we can allocate enough space to
  // store the match information.
  result.n_matches = 0;
  for (std::size_t i = 0; i < std::strlen(needle.text); i++) {
    switch (needle.text[i]) {
      case '\\':
        // The next character is escaped, so it can't possibly be the
        // metacharacter '('.  Skip it.
        i++;
        break;
      case '(':
        // That's our metacharacter.
        result.n_matches++;
        break;
      default:
        // Nothing interesting.
        break;
    }
  }
  // Allocate to store the match information.  Allocate one more slot than we
  // need, because the regex engine puts information about the entire match in
  // the first slot.
  result.matches =
      reinterpret_cast<regmatch_t*>(
          uw_malloc(context, (result.n_matches + 1) * sizeof(regmatch_t)));
  // Execute the regex.
  switch (regexec(needle.compiled, haystack, result.n_matches + 1,
                  result.matches, 0)) {
    case 0:
      // A match occurred.
      result.succeeded = 1;
      // Bump the matches array to skip information about the entire match.
      result.matches++;
      break;
    case REG_NOMATCH:
      // No match occurred.
      result.succeeded = 0;
      result.n_matches = 0;
      result.matches = nullptr;
      break;
    case REG_ESPACE:
      // We ran out of memory.
      uw_error(context, BOUNDED_RETRY, "regex: could not allocate");
    default:
      // Some unknown error occurred.
      uw_error(context, FATAL, "regex: could not execute regular expression");
  }
  return result;
}
