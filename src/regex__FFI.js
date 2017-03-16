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

Substring: {
  start: function(substring) {
    return substring.start;
  },

  length: function(substring) {
    return substring.length;
  },

  List: {
    length: function(list) {
      return list.length;
    },

    get: function(list, n) {
      return list[n];
    },
  },
},

doMatch: function(needle_string, haystack) {
  try {
    var needle = new RegExp(needle_string);
  } catch (e) {
    er("regex: compilation failed");
  }
  var result = needle.exec(haystack);
  if (result) {
    for (var i = 0; i < result.length; i++) {
      result[i] = {start: haystack.indexOf(result[i]),
                   length: result[i] !== undefined? result[i].length : 0};
    }
  } else {
    result = []
  }
  return result;
},

}};  // UrWeb.Regex
