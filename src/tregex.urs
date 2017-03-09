(* Abstract type of regular expressions. *)
con t :: {Unit} (* names of captured subgroups *) -> Type

(* ****** ****** *)

val literal :
    string -> t []
(*
val bol : t [] (* beginning of line: ^ *)
val eol : t [] (* end of line: $ *)
*)
val any : t []

(* ****** ****** *)

val concat : r1 ::: {Unit} -> r2 ::: {Unit} -> [r1 ~ r2] =>
    folder r1 ->
    folder r2 ->
    t r1 -> t r2 -> t (r1 ++ r2)

(* ****** ****** *)

val opt : r ::: {Unit} -> t r -> t r

datatype repetition =
	 Rexactly of int (* {N} *)
       | Rgte of int (* {N,} *)
       | Rlte of int (* {,N} *)
       | Rbtw of int * int (* {N,M} *)

val repeat : r ::: {Unit} -> t r -> repetition -> t r
val repeat_nongreedy : r ::: {Unit} -> t r -> repetition -> t r
val star : r ::: {Unit} -> t r -> t r
val star_nongreedy : r ::: {Unit} -> t r -> t r
val plus : r ::: {Unit} -> t r -> t r
val plus_nongreedy : r ::: {Unit} -> t r -> t r	 

(* ****** ****** *)

con char_class :: Type
    
val c_enum : string -> char_class (* simple case: abcdef *)
val c_rng : {Min : char, Max : char} -> char_class (* a-z *)
val c_join : r ::: {Unit} -> folder r -> $(mapU char_class r) -> char_class (* e.g. a-z012345 *)
val c_digit : char_class
val c_whitespace : char_class
val c_word : char_class
val c_boundary : char_class
val c_char : char -> char_class

val one_of : char_class -> t [] (* e.g. [abcdef] *)
val none_of : char_class -> t [] (* e.g. [^abcdef] *)

(* ****** ****** *)
			    
val alt : s1 ::: {Unit} -> s2 ::: {Unit} -> [s1 ~ s2] =>
    folder s1 -> folder s2 ->
    t s1 -> t s2 -> t (s1 ++ s2)
val capture : r ::: {Unit} -> nm :: Name -> [r ~ [nm]] =>
    folder r ->
    t r -> t (r ++ [nm])

(* ****** ****** *)

val groups : r ::: {Unit} -> t r -> folder r -> $(map (fn _ => int) r)
val show_tsregex : r ::: {Unit} -> show (t r)

(* ****** ****** *)

type counted_substring = {Start : int, Len : int}
con match = fn (r :: {Unit}) (a :: Type) => {Whole : a, Groups : $(map (fn _ => a) r)}

(* just a single match *)
val match : r ::: {Unit} -> folder r -> t r -> string -> option (match r (option string))

val match' : r ::: {Unit} -> folder r -> t r -> string -> option (match r counted_substring)

(* report all matches *)
val all_matches : r ::: {Unit} -> folder r -> t r -> string -> list (match r (option string))
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
								
