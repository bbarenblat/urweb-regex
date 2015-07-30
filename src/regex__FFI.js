// Copyright © 2015 Benjamin Barenblat
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

var UrWeb = { Regex: {

_compile: function(needle_string) {
  var needle;
  try {
    needle = new RegExp(needle_string);
  } catch (e) {
    er("regex: compilation failed");
  }
  return needle;
},

succeeded: function(match) {
  return !!match;
},

nSubexpressionMatches: function(match) {
  return match.length - 1;
},

subexpressionMatch: function(match, n) {
  if (match.length - 1 <= n) {
    er("regex: match does not exist");
  }
  return match[n + 1];
},

doMatch: function(needle, haystack) {
  return haystack.match(UrWeb.Regex._compile(needle));
},

replace: function(needle, replacement, haystack) {
  return haystack.replace(UrWeb.Regex._compile(needle), replacement);
},

}};  // UrWeb.Regex
