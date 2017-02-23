open Tregex

fun
test [r ::: {Unit}] (re: t r) (s: string) (i: int): string =
let
    val tre = show re
in
    if tre = s then "ok " ^ show i ^ " matches [" ^ s ^ "]"
    else "not ok " ^ show i ^ " got [" ^ tre ^ "] but should be [" ^ s ^ "]"
end

fun
tests [r ::: {{Unit}}] (x : $(map (fn x => t x * string) r)) (fl : folder r) =
  (@@Top.foldR
     [fn x => t x * string] [fn r => int * string]
     (fn [nm :: Name] [a :: {Unit}] [rest :: {{Unit}}] [[nm] ~ rest]
		      (g : t a * string) (f : int * string) =>
	 let
	     val res = test g.1 g.2 f.1
	 in
	     (f.1+1, f.2 ^ res)
	 end)
     (1, "") [r] fl x).2

fun format_results (res: string): transaction page =
    returnBlob (textBlob res) (blessMime "text/plain")
    
fun index (): transaction page =
    format_results
	(tests {
	 A = (alt (capture {X="x"} (literal "abcdef")) (concat (literal "Z") any), "(?:(?<x>abcdef))|(?:Z.)")
	 })
