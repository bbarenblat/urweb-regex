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

This library implements ECMAScript regular expressions. *)

type substring = {Start : int, Len : int}
type match = {Whole : substring, Groups : list substring}

(* Searching *)

(* Matches a regular expression against any part of a string.  Returns
'Some match' if a match succeeds and 'None' otherwise. *)
val match : string (* needle *)
            -> string (* haystack *)
            -> option match

(* Finds _all_ matches for a regular expression in a string. *)
val all_matches : string (* needle *)
                  -> string (* haystack *)
                  -> list match

(* Replacement *)

(* Replaces all substrings in 'haystack' that match 'needle' with the string
'replacement.' *)
val replace : string (* needle *)
              -> string (* replacement *)
              -> string (* haystack *)
              -> string

(* Transforms a string by applying a function to replace every match in the
string. *)
val transform_matches : string (* needle *)
                        -> (match -> string) (* transformation *)
                        -> string (* haystack *)
                        -> string

(* Executes a general regex-guided transformation over a string.  Matches
'needle' against any part of 'haystack', splitting 'haystack' into matching and
nonmatching regions.  Then, runs the provided transformation functions over the
regions and concatenates the results.

The number of nonmatching regions is always exactly one more than the number of
matching regions.  If two matching regions abut or a matching region adjoins the
edge of a string, this function will insert an empty nonmatching region as
appropriate.

An example may make this a bit clearer:

    let
      val haystack "axbxax"
    in
      transform "x"
                (fn nm => "_" ^ String.substring haystack nm ^ "_")
                (fn  m => "*" ^ String.substring haystack  m ^ "_")
                haystack
    end

evaluates to

    "_a_*x*_b_*x*__"
*)
val transform : string (* needle *)
                -> (substring -> string) (* non-matching transformation *)
                -> (match -> string) (* matching transformation *)
                -> string (* haystack *)
                -> string
