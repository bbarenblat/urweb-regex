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

fun literal s = {Groups = {}, NGroups = 0, Expr = escape s}

val any = {Groups = {}, NGroups = 0, Expr = "."}

fun concat [r1 ::: {Unit}] [r2 ::: {Unit}] [r1 ~ r2]
	   (flr1 : folder r1)
	   (flr2 : folder r2)
  (x : t r1) (y : t r2): t (r1 ++ r2) =
    {Groups = x.Groups ++ (@shift x.NGroups y.Groups flr2),
     NGroups = x.NGroups + y.NGroups,
     Expr = x.Expr ^ y.Expr}

fun star [r ::: {Unit}] (x: t r): t r =
    {Groups = x.Groups, NGroups = x.NGroups, Expr = "(?:" ^ x.Expr ^ ")*"}

fun projs [keep ::: {Type}] [drop ::: {Type}] [keep ~ drop] (xs : $(keep ++ drop)): $keep = xs --- drop

fun alt [s1 ::: {Unit}] [s2 ::: {Unit}] [s1 ~ s2]
	(fls1 : folder s1) (fls2 : folder s2)
	(x: t s1) (y : t s2): t (s1 ++ s2) =
    {Groups = x.Groups ++ (@shift x.NGroups y.Groups fls2),
     NGroups = x.NGroups + y.NGroups,
     Expr = "(?:" ^ x.Expr ^ ")|(?:" ^ y.Expr ^ ")"}

(*
additional cases?
- character classes, ranges: [a-Z]
https://www.debuggex.com/
*)

fun capture
	[r ::: {Unit}] [nm :: Name] [r ~ [nm]]
	(fl : folder r)
	(y: t r): t (r ++ [nm]) =
    {Groups = (@shift 1 y.Groups fl) ++ {nm = 0},
     NGroups = y.NGroups + 1,
     Expr = "(" ^ y.Expr ^ ")"}

(*
utility stuff?
eq, ord, show, sqlify instances for regexp (so we can save them to db...)
something else?

eq, ord <-- nope. no easy way to compare regexes
sqlify <-- nope. don't put into db!
 *)

fun groups [r ::: {Unit}] (x : t r) (fl : folder r): $(map (fn _ => int) r) = x.Groups

val show_tsregex = fn [r ::: {Unit}] => mkShow (fn x => x.Expr)

(*
problem: JS does not support named groups out of the box
fix:
http://lifesyntaxerrors.blogspot.com/2012/10/named-capturing-groups-in-javascript.html
*)
(*
useful unit-tests:

https://github.com/sweirich/dth/blob/master/popl17/src/RegexpTest.hs

fun match [r ::: {Unit}] (r: t r) (s : string): option (match r string) =
    let
	val result = Regex.match r.Expr s
    in
	
    end
 *)
