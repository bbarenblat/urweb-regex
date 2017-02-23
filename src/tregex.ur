type t = fn (r :: {Unit}) => {
	    Groups: $(map (fn _ => string) r),
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

fun literal s = {Groups = {}, Expr = escape s}

val any = {Groups = {}, Expr = "."}

fun concat [r1 ::: {Unit}] [r2 ::: {Unit}] [r1 ~ r2]
  (x : t r1) (y : t r2): t (r1 ++ r2) =
  {Groups = x.Groups ++ y.Groups, Expr = x.Expr ^ y.Expr}

fun star [r ::: {Unit}] (x: t r): t r =
    {Groups = x.Groups, Expr = "(?:" ^ x.Expr ^ ")*"}

fun projs [keep ::: {Type}] [drop ::: {Type}] [keep ~ drop] (xs : $(keep ++ drop)): $keep = xs --- drop    

fun alt [r ::: {Unit}] [s1 ::: {Unit}] [s2 ::: {Unit}] [r ~ s1] [r ~ s2] [s1 ~ s2]
  (x: t (r ++ s1)) (y : t (r ++ s2)): t (r ++ s1 ++ s2) =
{Groups = projs x.Groups ++ y.Groups, Expr = "(?:" ^ x.Expr ^ ")|(?:" ^ y.Expr ^ ")"}

(*
additional cases?
- character classes, ranges: [a-Z]
https://www.debuggex.com/
*)

fun capture
  [r ::: {Unit}] [nm ::: Name] [r ~ [nm]]
  (x: {nm : string}) (y: t r): t (r ++ [nm]) =
{Groups = y.Groups ++ x, Expr = "(?<" ^ x.nm ^ ">" ^ y.Expr ^ ")"}

(*
utility stuff?
eq, ord, show, sqlify instances for regexp (so we can save them to db...)
something else?

eq, ord <-- nope. no easy way to compare regexes
sqlify <-- nope. don't put into db!
*)

val show_tsregex = fn [r ::: {Unit}] => mkShow (fn x => x.Expr)

(*
problem: JS does not support named groups out of the box
fix:
http://lifesyntaxerrors.blogspot.com/2012/10/named-capturing-groups-in-javascript.html
*)

(* so exec becomes:
val
exec : r ::: {Unit} -> t r -> string -> $(map (fn _ => string) r)(*matches*)

or something more complicated, where we can signal failure
*)

(*
useful unit-tests:

https://github.com/sweirich/dth/blob/master/popl17/src/RegexpTest.hs
*)
