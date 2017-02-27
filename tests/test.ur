open Tregex

(* from meta/record *)
fun equal [ts ::: {Unit}] [a ::: Type]
	  (eqt : eq a)
	  (fl : folder ts)
	  (r1 : $(map (fn _ => a) ts))
	  (r2 : $(map (fn _ => a) ts)) : bool =
    @foldUR2 [a] [a] [fn _ => bool]
     (fn [nm ::_] [r ::_] [[nm] ~ r] x y acc =>
         acc && eq x y)
     True fl r1 r2

(* from "type-level computation" *)
fun showRecord [ts ::: {Unit}]
	       [a ::: Type]
	       (fl : folder ts)
	       (fnshow : a -> string)
	       (r : $(map (fn _ => a) ts)) : string =
					       "(" ^ @foldR
						      [fn _ => a] [fn _ => string]
						      (fn [nm ::_] [t ::_] [r ::_] [[nm] ~ r] value acc =>
							  fnshow value ^ ", " ^ acc)
						      ")" fl r
    
type test_eq = fn (a :: Type) (e :: {Unit}) => {E : t e, R : string, G : $(map (fn _ => a) e), F : folder e}

fun
test [r ::: {Unit}] (info: test_eq int r) (i: int): string =
let
    val tre = show info.E
    val gre = @groups info.E info.F
    fun show_index x = show x
in
    if tre = info.R && @equal eq_int info.F gre info.G
    then "ok " ^ show i ^ " matches [" ^ info.R ^ "] with groups [" ^
	 @showRecord info.F show_index info.G ^
	 "]"
    else "not ok " ^ show i ^ " got [" ^ tre ^ "] but should be [" ^ info.R ^ "], groups are ["
	 ^ @showRecord info.F show_index gre ^ "] but should be ["
	 ^ @showRecord info.F show_index info.G ^ "]"
end


fun
tests [r ::: {{Unit}}]
      (x : $(map (test_eq int) r))
      (fl : folder r) = let
    val count =
	@@Top.foldR
	  [test_eq int] [fn r => int]
	  (fn [nm :: Name] [a :: {Unit}] [rest :: {{Unit}}] [[nm] ~ rest]
			   (g : test_eq int a)
			   (f : int) => f+1)
	  0
	  [r] fl x
in
    "1.." ^ (show count) ^ "\n" ^
    (@@Top.foldR
       [test_eq int]
       [fn r => int * string]
       (fn [nm :: Name]
	       [a :: {Unit}]
	       [rest :: {{Unit}}]
	       [[nm] ~ rest]
	       (g : test_eq int a)
	       (f : int * string) =>
	   let
	       val res = @test g f.1
	   in
	       (f.1-1, res ^ "\n" ^ f.2)
	   end)
       (count, "") [r] fl x).2
end

fun
test_match_string [r ::: {Unit}] (info: test_eq string r) (i: int): string =
let
    val m = @Tregex.match info.F info.E info.R
    fun show_group x = "[" ^ show x ^ "]"
in
    case m of
	None => "not ok " ^ show i ^ " got None, expecting " ^ @showRecord info.F show_group info.G
      | Some {Whole = whole, Groups = g} =>
	if @equal eq_string info.F g info.G
	then "ok " ^ show i ^ " matches"
	else "not ok " ^ show i ^ " mismatches: groups are ["
	     ^ @showRecord info.F show_group g ^ "] but should be ["
	     ^ @showRecord info.F show_group info.G ^ "]"
end

fun
tests_match_string [r ::: {{Unit}}]
      (x : $(map (test_eq string) r))
      (fl : folder r) = let
    val count =
	@@Top.foldR
	  [test_eq string] [fn r => int]
	  (fn [nm :: Name] [a :: {Unit}] [rest :: {{Unit}}] [[nm] ~ rest]
			   (g : test_eq string a)
			   (f : int) => f+1)
	  0
	  [r] fl x
in
    "1.." ^ (show count) ^ "\n" ^
    (@@Top.foldR
       [test_eq string]
       [fn r => int * string]
       (fn [nm :: Name]
	       [a :: {Unit}]
	       [rest :: {{Unit}}]
	       [[nm] ~ rest]
	       (g : test_eq string a)
	       (f : int * string) =>
	   let
	       val res = @test_match_string g f.1
	   in
	       (f.1-1, res ^ "\n" ^ f.2)
	   end)
       (count, "") [r] fl x).2
end

fun format_results (res: string): transaction page =
    returnBlob (textBlob res) (blessMime "text/plain")

fun index (): transaction page =
    format_results
	(tests (
	 {E = concat (literal "a") (capture [#X] (literal "b")), R = "a(b)", G = {X=0}, F = _},
	 {E = alt (capture [#X] (literal "abcdef")) (concat (literal "Z") any), R = "(?:(abcdef))|(?:Z.)", G = {X=0}, F = _},
	 {E = concat (capture [#A] (literal "ab")) (concat (literal "c") (capture [#B] (literal "d"))), R = "(ab)c(d)", G = {A=0, B=1}, F = _},
	 {E = capture [#C] (concat (capture [#A] (literal "ab")) (concat (literal "c") (capture [#B] (literal "d")))), R = "((ab)c(d))", G = {A=1, B=2, C=0}, F = _},
	 {E = capture [#A] (concat (literal "z") (capture [#B] (literal "a"))), R = "(z(a))", G = {A=0, B=1}, F = _}
	))

fun groups (): transaction page =
    m <- return ((Tregex.match'
		(concat (literal "a") (capture [#X] (literal "b")))
		"ab") : option {Whole:counted_substring, Groups:{X:counted_substring}});
    
    case m of
	None => return <xml>Failed: mismatch!</xml>
      | Some {Whole = whole, Groups = {X = {Start=s,Len=l}}} => return <xml>Success? Whole match: {[whole.Start]} + {[whole.Len]}, group is {[s]} + {[l]}</xml>

    (*
    format_results
	(tests_match_string (
	 {E = concat (literal "a") (capture [#X] (literal "b")), R = "ab", G = {X="b"}, F = _},
	 {E = alt (capture [#X] (literal "abcdef")) (concat (literal "Z") any), R = "abcdef", G = {X="abcdef"}, F = _},
	 {E = concat (capture [#A] (literal "ab")) (concat (literal "c") (capture [#B] (literal "d"))), R = "abcd", G = {A="ab", B="d"}, F = _},
	 {E = capture [#C] (concat (capture [#A] (literal "ab")) (concat (literal "c") (capture [#B] (literal "d")))), R = "abcd", G = {A="ab", B="d", C="abcd"}, F = _},
	 {E = capture [#A] (concat (literal "z") (capture [#B] (literal "a"))), R = "za", G = {A="za", B="a"}, F = _}
	 )) *)

fun sum [t] (_ : num t) [fs ::: {Unit}] (fl : folder fs) (x : $(mapU t fs)) =
    @foldUR [t] [fn _ => t]
     (fn [nm :: Name] [rest :: {Unit}] [[nm] ~ rest] n acc => n + acc)
     zero fl x

fun testfold (): transaction page = return <xml><body>
  {[sum {A = 0, B = 1}]}<br/>
  {[sum {C = 2.1, D = 3.2, E = 4.3}]}
</body></xml>    