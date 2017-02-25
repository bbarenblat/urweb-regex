open Tregex

(* from meta/record *)
fun equal [ts ::: {Unit}] (fl : folder ts) (r1 : $(map (fn _ => int) ts)) (r2 : $(map (fn _ => int) ts)) : bool =
    @foldUR2 [int] [int] [fn _ => bool]
     (fn [nm ::_] [r ::_] [[nm] ~ r] x y acc =>
         acc && x = y)
     True fl r1 r2

(* from "type-level computation" *)
fun showRecord [ts ::: {Unit}]
	       (fl : folder ts)
	       (r : $(map (fn _ => int) ts)) : string =
					       "(" ^ @foldR
						      [fn _ => int] [fn _ => string]
						      (fn [nm ::_] [t ::_] [r ::_] [[nm] ~ r] value acc =>
							  show value ^ ", " ^ acc)
						      ")" fl r
    
type test_eq = fn (e :: {Unit}) => {E : t e, R : string, G : $(map (fn _ => int) e), F : folder e}

fun
test [r ::: {Unit}] (info: test_eq r) (i: int): string =
let
    val tre = show info.E
    val gre = @groups info.E info.F
in
    if tre = info.R && @equal info.F gre info.G
    then "ok " ^ show i ^ " matches [" ^ info.R ^ "] with groups [" ^ @showRecord info.F info.G ^ "]"
    else "not ok " ^ show i ^ " got [" ^ tre ^ "] but should be [" ^ info.R ^ "], groups are ["
	 ^ @showRecord info.F gre ^ "] but should be ["
	 ^ @showRecord info.F info.G ^ "]"
end


fun
tests [r ::: {{Unit}}]
      (x : $(map test_eq r))
      (fl : folder r) = let
    val count =
	@@Top.foldR
	  [test_eq] [fn r => int]
	  (fn [nm :: Name] [a :: {Unit}] [rest :: {{Unit}}] [[nm] ~ rest]
			   (g : test_eq a)
			   (f : int) => f+1)
	  0
	  [r] fl x
in
    "1.." ^ (show count) ^ "\n" ^
    (@@Top.foldR
       [test_eq]
       [fn r => int * string]
       (fn [nm :: Name]
	       [a :: {Unit}]
	       [rest :: {{Unit}}]
	       [[nm] ~ rest]
	       (g : test_eq a)
	       (f : int * string) =>
	   let
	       val res = @test g f.1
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
	 {E = capture [#C] (concat (capture [#A] (literal "ab")) (concat (literal "c") (capture [#B] (literal "d")))), R = "((ab)c(d))", G = {C=0, A=1, B=2}, F = _}
	))

fun sum [t] (_ : num t) [fs ::: {Unit}] (fl : folder fs) (x : $(mapU t fs)) =
    @foldUR [t] [fn _ => t]
     (fn [nm :: Name] [rest :: {Unit}] [[nm] ~ rest] n acc => n + acc)
     zero fl x

fun testfold (): transaction page = return <xml><body>
  {[sum {A = 0, B = 1}]}<br/>
  {[sum {C = 2.1, D = 3.2, E = 4.3}]}
</body></xml>    
