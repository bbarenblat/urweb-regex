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

structure FFI = Regex__FFI

fun match regex input =
  (* Perform the match. *)
  let
    val result = FFI.do_match regex input
  in
    if not (FFI.succeeded result)
    then
      (* No match occurred. *)
      None
    else
      (* Get the subexpressions.  We must do this iteratively, as the Regex__FFI
      API can't return a list of matches. *)
      let
        fun loop i =
          if i = FFI.n_subexpression_matches result
          then
            (* We've got all the subexpressions. *)
            []
          else FFI.subexpression_match result i :: loop (i + 1)
      in
        Some (loop 0)
      end
  end

val replace = FFI.replace
