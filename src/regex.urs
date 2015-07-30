(* Copyright 2015 the Massachusetts Institute of Technology
Copyright 2015 Benjamin Barenblat

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License. *)

(* Regular expression matching

This library implements POSIX extended regular expressions, which most closely
match what 'normal' people think about when they hear 'regular expressions'.
Here's a brief syntax reminder:

  .[]^$()\*{}?+| are metacharacters and must be backslash-escaped if you want to
  use them.  (Remember, in Ur/Web, backslash is also the string escape
  character, so if you want to match a literal open brace, you need to specify
  "\\{", if you want to match a literal backslash, you need to specify "\\\\",
  etc.)

  . matches any character
  x? matches 'x' zero or one time
  x* matches 'x' zero or more times
  x+ matches 'x' one or more times
  x{3,5} matches 'xxx', 'xxxx', and 'xxxxx'

  ^ matches the start of a line
  $ matches the end of a line

  [abcx-z] matches 'a', 'b', 'c', 'x', 'y', or 'z'
  [^a-z] matches any single character not equal to 'a', 'b', ..., or 'z'

  (abc) matches the string 'abc' and saves it as a marked subexpression
  \3 matches the 3rd marked subexpression

  Character classes may be used inside bracket expressions:
  [:alnum:]   [A-Za-z0-9]                         alphanumeric characters
  [:alpha:]   [A-Za-z]                            alphabetic characters
  [:blank:]   [ \t]                               space and tab
  [:cntrl:]   [\x00-\x1F\x7F]                     control characters
  [:digit:]   [0-9]                               digits
  [:graph:]   [\x21-\x7E]                         visible characters
  [:lower:]   [a-z]                               lowercase letters
  [:print:]   [\x20-\x7E]                         visible characters and the space character
  [:punct:]   [][!"#$%&'()*+,./:;<=>?@\^_`{|}~-]  punctuation characters
  [:space:]   [ \t\r\n\v\f]                       whitespace characters
  [:upper:]   [A-Z]                               uppercase letters
  [:xdigit:]  [A-Fa-f0-9]                         Hexadecimal digits
  So if you want to match all duodecimal digits, you can specify
  '[[:digit:]A-Ba-b]'.  If you simply want all decimal digits, you need
  '[[:digit:]]'. *)


(* Searching *)

(* Matches a regular expression against any part of a string.  Returns 'Some
strs', where 'strs' is a list of subexpression matches, if a match succeeds, and
'None' otherwise. *)
val match : string (* needle *)
         -> string (* haystack *)
         -> option (list string)
