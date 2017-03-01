type t = fn (r :: {Unit}) => {
	    Groups : $(map (fn _ => int) r),
	    NGroups : int,
	    Expr : string
	    }

fun escape s = let
    fun esc s =
	case s of
	    "" => ""
	  | _ =>
	    let
		val ch = String.sub s 0
	    in
		(if ch = #"-" || ch = #"/" || ch = #"\\" || ch = #"^"
		    || ch = #"$" || ch = #"*" || ch = #"+" || ch = #"?"
		    || ch = #"." || ch = #"(" || ch = #")" || ch = #"|"
		    || ch = #"[" || ch = #"]" || ch = #"{" || ch = #"}"
		 then "\\" ^ String.str ch
		 else String.str ch) ^ esc (String.suffix s 1)
	    end
in
    esc s
end

(* ****** ****** *)

(*
(ab)c(d)
--> by order, left to right?
--> gives groups: 1 for (ab), 2 for (d)
((a)b)c(d)
--> again, left to right ordering, nesting notwithstanding
--> gives groups: 1 for ((a)b), 2 for (a), 3 for (d)

how about a pure Urweb regexp? https://www.cs.cmu.edu/~rwh/introsml/samplecode/regexp.sml haha, you seem to be joking.

how to express in urweb? should we somehow allow user to specify this directly in the match function?
- (capture [#Foo] (literal "ab"), literal "c", capture [#Bar] (literal "d")) <-- we use a tuple here.
- there exists JSON if that may help you

capture (cat (literal "a") (capture (literal "b")))
^^^^^^^ group 1
                                   ^^^^^^^ group 2
when building up expressions, have to change the indexes somehow
step a: (capture (literal "b")) <-- group is 0
step b: capture (cat (literal "a") (capture (literal "b")))
  - now, group 0 is the outermost capture; the inner captures have to be "fixed"
    - go through the tree, incrementing stuff... how?
    - group 0: increase by 1, it now becomes group 1
- step c: cat (capture (cat (literal "a") (capture (literal "b"))), capture (literal "d"))
  - now, group 0 is still group 0,
  - and group 1 is still group 1...
  - but the new group will be group 2 (it's maximum group in expr so far + 1)
- we need to keep track of "the number of capturing groups in expression X", abbrev. ncap(X), e.g.:
  - ncap([a-z]) = 0
    - [a-z] = {Groups={}, NGroups=0, Expr = "[a-z]"}
  - ncap(capture([a-z])) = 1
    - capture([a-z]) = {Groups={A=0}, NGroups = 1, Expr = "([a-z])"}
  - ncap(cat([a-z],capture([a-z])) = 1
    - cat([a-z],capture([a-z]) = {Groups={A=0}, NGroups = 1, Expr = "[a-z]([a-z])"}
  - ncap(cat([0-9], cat([a-z], capture([a-z]))) = 1
    - cat([0-9], cat([a-z], capture([a-z])) = {Groups={A=0}, NGroups = 1, Expr = "[0-9][a-z]([a-z])"}
  - ncap(cat(capture([0-9]), capture([a-z]))) = 2
     - cat(capture([0-9]), capture([a-z])) = {Groups = {A = 1, B = 0}, NGroups = 2, Expr = "([0-9])([a-z])"}
- so, whether group counts have to increase depends on:
  - where do we put the new expression chunks:
    - if we have A, and we use it to build AB, then B's counters have to increase by as much as A's max counter is (while A stays intact)
    - if we have A, and we also have B, and we use it to build B|A, we have to increase counters of A (the RHS)
- increase to max(lhs)+1: alt, cat
- capture (embedded counters go +1)
- what about nested groups:
  - (a(b))
  - capture (cat (literal "a") (capture (literal "b"))
  - capture (literal "b") = {Groups = {A=0}, NGroups = 1, Expr = "(b)"}
  - cat (literal "a") (capture (literal "b")) = {Groups = {A=0}, NGroups = 1, Expr ="a(b)"}
  - capture (cat (literal "a") (capture (literal "b"))) = {Groups = {A=1, B=2}, NGroups = 1, 2, Expr = "(a(b))"}
    - capture n e = {Groups = (shift (+1) e.Groups) ++ {n=0}, NGroups = e.NGroups+1, Expr = "(" ^ e.Expr ^ ")"} <-- shift applies a function to all elements of a unityped record, producing another record
*)

fun
shift
    [r ::: {Unit}]
    (n : int)
    (c : $(map (fn _ => int) r))
    (fl : folder r): $(map (fn _ => int) r) =
		     @foldUR
		       [int]
		       [fn r => $(map (fn _ => int) r)]
		       (fn [nm ::_] [rest ::_] [[nm]~rest] x acc =>
			   acc ++ {nm= n+x})
		       {}
		       fl
		       c

(* ****** ****** *)
		       
fun literal s = {Groups = {}, NGroups = 0, Expr = escape s}

val any = {Groups = {}, NGroups = 0, Expr = "."}

fun concat [r1 ::: {Unit}] [r2 ::: {Unit}] [r1 ~ r2]
	   (flr1 : folder r1)
	   (flr2 : folder r2)
  (x : t r1) (y : t r2): t (r1 ++ r2) =
    {Groups = x.Groups ++ (@shift x.NGroups y.Groups flr2),
     NGroups = x.NGroups + y.NGroups,
     Expr = x.Expr ^ y.Expr}

(* ****** ****** *)

datatype repetition =
	 Rexactly of int (* {N} *)
       | Rgte of int (* {N,} *)
       | Rlte of int (* {,N} *)
       | Rbtw of (int * int) (* {N,M} *)

fun repeat [r ::: {Unit}] (x : t r) (rep : repetition): t r =
    {Groups = x.Groups,
     NGroups = x.NGroups,
     Expr = "(?:" ^ x.Expr ^ "){" ^
	    (case rep of
		 Rexactly n => show n
	       | Rgte n => show n ^ ","
	       | Rlte n => "," ^ show n
	       | Rbtw (m, n) => show m ^ "," ^ show n
	    ) ^ "}"}
fun repeat_nongreedy [r ::: {Unit}] (x : t r) (rep : repetition): t r =
    let
	val res = repeat x rep
    in
	{Groups = res.Groups, NGroups = res.NGroups, Expr = res.Expr ^ "?"}
    end

fun star [r ::: {Unit}] (x: t r): t r =
    {Groups = x.Groups, NGroups = x.NGroups, Expr = "(?:" ^ x.Expr ^ ")*"}
fun star_nongreedy [r ::: {Unit}] (x: t r): t r =
    let
	val res = star x
    in
	{Groups = res.Groups, NGroups = res.NGroups, Expr = res.Expr ^ "?"}
    end
    
fun plus [r ::: {Unit}] (x: t r): t r =
    {Groups = x.Groups, NGroups = x.NGroups, Expr = "(?:" ^ x.Expr ^ ")+"}
fun plus_nongreedy [r ::: {Unit}] (x: t r): t r =
    let
	val res = plus x
    in
	{Groups = res.Groups, NGroups = res.NGroups, Expr = res.Expr ^ "?"}
    end

(* ****** ****** *)
    
type char_class = string

fun c_enum (s : string) : char_class = escape s

fun c_rng (x : {Min : char, Max : char}) : char_class =
    escape (String.str x.Min) ^ "-" ^ escape (String.str x.Max)

fun c_join [r ::: {Unit}] (fl : folder r) (cs : $(mapU char_class r)) : char_class =
    @foldUR
     [char_class] [fn r => char_class]
     (fn [nm ::_] [rest ::_] [[nm] ~ rest] (cc : char_class) acc => acc ^ cc)
     ""
     fl
     cs

val c_digit = "\\d"
val c_whitespace = "\\s"
val c_word = "\\w"
val c_boundary = "[\\b]"

fun c_char (c : char) = escape (String.str c)

fun one_of (cc : char_class) : t [] = {Groups = {}, NGroups = 0, Expr = "[" ^ cc ^ "]"}
fun none_of (cc : char_class) : t [] = {Groups = {}, NGroups = 0, Expr = "[^" ^ cc ^ "]"}

(* ****** ****** *)
			
fun projs [keep ::: {Type}] [drop ::: {Type}] [keep ~ drop] (xs : $(keep ++ drop)): $keep = xs --- drop

fun alt [s1 ::: {Unit}] [s2 ::: {Unit}] [s1 ~ s2]
	(fls1 : folder s1) (fls2 : folder s2)
	(x: t s1) (y : t s2): t (s1 ++ s2) =
    {Groups = x.Groups ++ (@shift x.NGroups y.Groups fls2),
     NGroups = x.NGroups + y.NGroups,
     Expr = "(?:" ^ x.Expr ^ ")|(?:" ^ y.Expr ^ ")"}

(* ****** ****** *)
    
fun capture
	[r ::: {Unit}] [nm :: Name] [r ~ [nm]]
	(fl : folder r)
	(y: t r): t (r ++ [nm]) =
    {Groups = (@shift 1 y.Groups fl) ++ {nm = 0},
     NGroups = y.NGroups + 1,
     Expr = "(" ^ y.Expr ^ ")"}

(* ****** ****** *)

fun groups [r ::: {Unit}] (x : t r) (fl : folder r): $(map (fn _ => int) r) = x.Groups

val show_tsregex = fn [r ::: {Unit}] => mkShow (fn x => x.Expr)

(* ****** ****** *)

type counted_substring = {Start : int, Len : int}					
con match = fn (r :: {Unit}) (a :: Type) => {Whole : a, Groups : $(map (fn _ => a) r)}

fun substring_offset (delta : int) (substring : counted_substring)
    : counted_substring =
    {Start = substring.Start + delta, Len = substring.Len}

fun match_mp [r ::: {Unit}]
	     [a ::: Type]
	     [b ::: Type]
	     (f : a -> b)
	     (fl : folder r)
	     (match : match r a) : match r b =
    {Whole = f match.Whole,
     Groups =
     @mp [fn _ => a] [fn _ => b] (fn [t] x => f x) fl match.Groups}

fun match_offset
	[r ::: {Unit}]
	(delta : int)
	(fl : folder r)
	(m : match r counted_substring)
    : match r counted_substring =
    {Whole = substring_offset delta m.Whole,
     Groups =
     @mp [fn _ => counted_substring] [fn _ => counted_substring] (fn [t] x => substring_offset delta x) fl m.Groups}

(* Returns the index of the character just _after_ a match. *)
fun after_match [r ::: {Unit}] (match : match r counted_substring) : int =
  match.Whole.Start + match.Whole.Len

fun get_substrings [r ::: {Unit}] (fl : folder r)
		   (haystack : string) (m : match r counted_substring) : match r string =
    {Whole = String.substring haystack m.Whole,
     Groups =
     @mp [fn _ => counted_substring] [fn _ => string] (fn [t] x => String.substring haystack x) fl m.Groups}

(* Unmarshaling FFI types *)

structure FFI = Regex__FFI

(* Unmarshals an 'FFI.substring_t' from C into Ur. *)
fun unmarshal_substring (substring : FFI.substring_t) : counted_substring =
  {Start = FFI.substring_start substring,
   Len = FFI.substring_length substring}

(* Unmarshals an 'FFI.substring_list_t' from C into Ur. *)
fun
unmarshal_substring_list
    [r ::: {Unit}]
    (fl : folder r)
    (ngroups : int)
    (groups : $(map (fn _ => int) r))
    (substrings : FFI.substring_list_t)
: option (match r counted_substring) =
  let
      (* go over groups: for each group, retrieve its value by index *)
      val n = FFI.substring_list_length substrings
  in
      case n of
	  0 => None
	| n_groups =>
	  if n_groups <> (ngroups+1) then error <xml>unmarshal_substring_list: mismatch of group counts, expected {[ngroups]}, got {[n_groups]}</xml>
	  else
	      Some {Whole = unmarshal_substring (FFI.substring_list_get substrings 0),
		    Groups =
		    @foldUR [int] [fn r => $(map (fn _ => counted_substring) r)]
		     (fn [nm ::_] [rest ::_] [[nm] ~ rest]
				  (i : int)
				  acc => let
			     val ss = FFI.substring_list_get substrings (i+1)
			     val v =  {Start = FFI.substring_start ss,  Len = FFI.substring_length ss}
			 in
			     acc ++ {nm = v}
			 end)
		     {}
		     fl
		     groups
		   }
  end

fun match' [r ::: {Unit}]
	   (fl : folder r)
	   (needle : t r)
	   (haystack : string): option (match r counted_substring) =
    @unmarshal_substring_list
     fl
     needle.NGroups
     needle.Groups
     (FFI.do_match needle.Expr haystack)

fun match [r ::: {Unit}]
	  (fl : folder r)
	  (needle : t r)
	  (haystack : string): option (match r string) =
    let
	val res = @match' fl needle haystack
    in
	case res of
	    None => None
	  | Some m => Some (@get_substrings fl haystack m)
    end
    
fun all_matches' [r ::: {Unit}] (fl : folder r) (needle : t r) (haystack : string): list (match r counted_substring) =
    case @match' fl needle haystack of
	None => []
      | Some match =>
	let
	    val remaining_start = after_match match
	in
	    match :: List.mp
		  (fn x => @match_offset remaining_start fl x)
		  (@all_matches' fl needle (String.suffix haystack remaining_start))
	end

fun all_matches [r ::: {Unit}]
		(fl : folder r)
		(needle : t r)
		(haystack : string): list (match r string) =
    List.mp (@get_substrings fl haystack) (@all_matches' fl needle haystack)

													  
