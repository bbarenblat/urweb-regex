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

(* This is an internal module.  You should use the high-level API in Regex
instead. *)

(* Ideally, these types would be declared in a nice module hierarchy.
Unfortunately, Ur/Web bug #207 makes that impossible. *)
type substring_t
val substring_start : substring_t -> int
val substring_length : substring_t -> int

type substring_list_t
val substring_list_length : substring_list_t -> int
val substring_list_get : substring_list_t -> int -> substring_t

(* Matches a regular expression against any part of a string.  Returns a list of
groups.  The zeroth element of each match represents the match as a whole.
Thus, matching /a(b*c)d/ against

              1    1
    0    5    0    5
    __acd__abbbbcd__

will yield

    [(2,3), (3, 1)]

where (x,y) is a substring with start x and length y. *)
val do_match : string (* needle *)
            -> string (* haystack *)
            -> substring_list_t
