(* Abstract type of regular expressions. *)
con t :: {Unit} (* names of captured subgroups *) -> Type

val literal :
    string -> t []
(*
val bol : t [] (* beginning of line: ^ *)
val eol : t [] (* end of line: $ *)
*)
val any : t []
val concat : r1 ::: {Unit} -> r2 ::: {Unit} -> [r1 ~ r2] =>
    folder r1 ->
    folder r2 ->
    t r1 -> t r2 -> t (r1 ++ r2)
val star : r ::: {Unit} ->
    t r -> t r
(*
more operators:
(*
cases for repeats/multiplicity:

1 or more: * (same as {1,})
0 or more: + (same as {0,})
at least N: {N,}
at most N: {,N}
exactly N: {N}
between N and M: {N,M}

also, may want to specify matching type:
- greedy (default)
- non-greedy
*)

character classes
.
\d == [0-9]
\D == [^0-9]
\w == [A-Za-z0-9_]
\W == [^A-Za-z0-9_]
\s == [ \f\n\r\t\v\u00a0\u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]
\S == [^ \f\n\r\t\v\u00a0\u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]
\t
\r
\n
\v
\f
[\b]
\0
\cX where X in A..Z
\xhh, where h is hex digit

[abc]
[a-z]
[^abc]
[^a-z]

https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/RegExp

type char_class (* actually a string! *)
val enumerate : string -> char_class (* simple case: abcdef *)
(* the string is escaped! before it gets anywhere *)
val from_to : char * char -> char_class (* a-z *)
val join : char_class -> char_class -> char_class (* e.g. a-z012345 *)
(* we might also want to put there: ., something escaped *)

(* finally, using it in a bigger regexp: *)
val one_of : char_class -> t [] (* e.g. [abcdef] *)
val none_of : char_class -> t [] (* e.g. [^abcdef] *)

bigger stuff: alpha, alnum, digit, word, word boundary
also part of char_class

also, assertions! (followed-by and not-followed-by)
*)
val alt : s1 ::: {Unit} -> s2 ::: {Unit} -> [s1 ~ s2] =>
    folder s1 -> folder s2 ->
    t s1 -> t s2 -> t (s1 ++ s2)
val capture : r ::: {Unit} -> nm :: Name -> [r ~ [nm]] =>
    folder r ->
    t r -> t (r ++ [nm])

val groups : r ::: {Unit} -> t r -> folder r -> $(map (fn _ => int) r)
val show_tsregex : r ::: {Unit} -> show (t r)

(* ****** ****** *)

type counted_substring = {Start : int, Len : int}
con match = fn (r :: {Unit}) (a :: Type) => {Whole : a, Groups : $(map (fn _ => a) r)}

(* just a single match *)
val match : r ::: {Unit} -> folder r -> t r -> string -> option (match r string)

val match' : r ::: {Unit} -> folder r -> t r -> string -> option (match r counted_substring)

(* report all matches *)
val all_matches : r ::: {Unit} -> folder r -> t r -> string -> list (match r string)
val all_matches' : r ::: {Unit} -> folder r -> t r -> string -> list (match r counted_substring)

								(*
(* replace all matches *)
val replace
    : r ::: {Unit}
      -> folder r
      -> $(map (fn _ => string) r)(*replacements*)
      -> string(*haystack*)
      -> t r(*needle*) -> string(*new string*)
		   
								 *)
								
