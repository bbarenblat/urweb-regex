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

(* Utility *)

fun concat (strings : list string) : string =
  List.foldr String.append "" strings


(* Substrings and matches *)

type substring = {Start : int, Len : int}
type match = {Whole : substring, Groups : list substring}

fun substring_offset (delta : int) (substring : substring) : substring =
  {Start = substring.Start + delta, Len = substring.Len}

fun match_offset (delta : int) (match : match) : match =
  {Whole = substring_offset delta match.Whole,
   Groups = List.mp (substring_offset delta) match.Groups}

(* Returns the index of the character just _after_ a match. *)
fun after_match (match : match) : int =
  match.Whole.Start + match.Whole.Len


(* Unmarshaling FFI types *)

structure FFI = Regex__FFI

(* Unmarshals an 'FFI.substring_t' from C into Ur. *)
fun unmarshal_substring (substring : FFI.substring_t) : substring =
  {Start = FFI.substring_start substring,
   Len = FFI.substring_length substring}

(* Unmarshals an 'FFI.substring_list_t' from C into Ur. *)
fun unmarshal_substring_list (substrings : FFI.substring_list_t)
    : option match =
  case FFI.substring_list_length substrings of
      0 => None
    | n_groups =>
      let
        fun loop n =
          if n_groups <= n
          then []
          else unmarshal_substring (FFI.substring_list_get substrings n)
                 :: loop (n + 1)
      in
        Some {Whole = unmarshal_substring (FFI.substring_list_get substrings 0),
              Groups = loop 1}
      end


(* Regular expressions *)

(* Ensures that a regex is not going to cause problems later down the line. *)
fun validate (regex : string) : string =
  if String.lengthGe regex 1
  then regex
  else error <xml>regex: Empty regex</xml>

fun match needle haystack =
  unmarshal_substring_list (FFI.do_match (validate needle) haystack)

fun all_matches needle haystack =
  case match needle haystack of
      None => []
    | Some match =>
      let
        val remaining_start = after_match match
      in
        match
          :: List.mp (match_offset remaining_start)
                     (all_matches needle
                                  (String.suffix haystack remaining_start))
      end

fun transform needle f_nomatch f_match haystack =
  let
    val haystack_length = String.length haystack
    val matches = all_matches needle haystack
  in
    (* Handle the first nonmatching region. *)
    f_nomatch {Start = 0,
               Len = case matches of
                         [] => haystack_length
                       | first_match :: _ => first_match.Whole.Start}
    ^
    (* Handle the remaining regions. *)
    concat
      (List.mapi
         (fn match_number match =>
            (* Handle the matching region. *)
            f_match match
            ^
            (* Handle the nonmatching region. *)
            let
              val start = match.Whole.Start + match.Whole.Len
            in
              f_nomatch {Start = start,
                         Len =
                           case List.nth matches (match_number + 1) of
                               None =>
                               (* We’re on the last matching region in the
                               string, so the nonmatching region lasts until the
                               end of the string. *)
                               haystack_length - start
                             | Some next_match =>
                               next_match.Whole.Start - start}
            end)
         matches)
  end

fun transform_matches needle f_match haystack =
  transform needle (String.substring haystack) f_match haystack

fun replace needle haystack replacement =
  transform_matches needle (fn _ => replacement) haystack
