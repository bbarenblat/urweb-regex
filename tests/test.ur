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

val eq_option_string = @Option.eq eq_string
val show_option_string = mkShow (fn x =>
				    case x of
					None => "None"
				      | Some x => "Some([" ^ x ^ "])")

fun
test_match_string [r ::: {Unit}] (info: test_eq (option string) r) (i: int): string =
let
    val m = @Tregex.match info.F info.E info.R
    fun show_group x = @show show_option_string x
in
    case m of
	None => "not ok " ^ show i ^ " got None, expecting " ^ @showRecord info.F show_group info.G
      | Some {Whole = whole, Groups = g} =>
	if @equal eq_option_string info.F g info.G
	then "ok " ^ show i ^ " matches"
	else "not ok " ^ show i ^ " mismatches: groups are ["
	     ^ @showRecord info.F show_group g ^ "] but should be ["
	     ^ @showRecord info.F show_group info.G ^ "]"
end

fun
tests_match_string [r ::: {{Unit}}]
      (x : $(map (test_eq (option string)) r))
      (fl : folder r) = let
    val count =
	@@Top.foldR
	  [test_eq (option string)] [fn r => int]
	  (fn [nm :: Name] [a :: {Unit}] [rest :: {{Unit}}] [[nm] ~ rest]
			   (g : test_eq (option string) a)
			   (f : int) => f+1)
	  0
	  [r] fl x
in
    "1.." ^ (show count) ^ "\n" ^
    (@@Top.foldR
       [test_eq (option string)]
       [fn r => int * string]
       (fn [nm :: Name]
	       [a :: {Unit}]
	       [rest :: {{Unit}}]
	       [[nm] ~ rest]
	       (g : test_eq (option string) a)
	       (f : int * string) =>
	   let
	       val res = @test_match_string g f.1
	   in
	       (f.1-1, res ^ "\n" ^ f.2)
	   end)
       (count, "") [r] fl x).2
end

(*  ****** ****** *)

fun
match_eq
    [r ::: {Unit}]
    (fl : folder r)
    (x : t r)
    (s : string)
    (grp : $(map (fn _ => option string) r))
    (i: int): string =
let
    val m = @Tregex.match fl x s
    fun show_group x = @show show_option_string x
in
    case m of
	None => "not ok " ^ show i ^ " got None, expecting " ^ @showRecord fl show_group grp
      | Some {Whole = whole, Groups = g} =>
	if @equal eq_option_string fl g grp
	then "ok " ^ show i ^ " matches"
	else "not ok " ^ show i ^ " mismatches: groups are ["
	     ^ @showRecord fl show_group g ^ "] but should be ["
	     ^ @showRecord fl show_group grp ^ "]"
end

(*  ****** ****** *)

fun format_results (res: string): transaction page =
    returnBlob (textBlob res) (blessMime "text/plain")
    (*
fun format_results_client (res : transaction string) : transaction page =
    return <xml>
      <head>
	<title>Test</title>
      </head>
      <body>
	<active code={r <- res; return <xml><pre>{[r]}</pre></xml>}/>
    </body>
</xml>*)


(*  ****** ****** *)

fun index_tests () =
    tests (
    {E = concat (literal "a") (capture [#X] (literal "b")), R = "a(b)", G = {X=0}, F = _},
    {E = alt (capture [#X] (literal "abcdef")) (concat (literal "Z") any), R = "(?:(abcdef))|(?:Z.)", G = {X=0}, F = _},
    {E = concat (capture [#A] (literal "ab")) (concat (literal "c") (capture [#B] (literal "d"))), R = "(ab)c(d)", G = {A=0, B=1}, F = _},
    {E = capture [#C] (concat (capture [#A] (literal "ab")) (concat (literal "c") (capture [#B] (literal "d")))), R = "((ab)c(d))", G = {A=1, B=2, C=0}, F = _},
    {E = capture [#A] (concat (literal "z") (capture [#B] (literal "a"))), R = "(z(a))", G = {A=0, B=1}, F = _})
	
fun index (): transaction page =
    format_results (index_tests ())
fun index_client (): transaction page =
(*    format_results_client (return (index_tests ()))*)
    return <xml>
      <head>
	<title>Test</title>
      </head>
      <body>
	<active code={let val r = index_tests () in return <xml><pre>{[r]}</pre></xml> end}/>
    </body>
</xml>

(*  ****** ****** *)

fun groups_test () =
    s1 <- return (
	  match_eq (concat (literal "a") (capture [#X] (literal "b"))) "ab" {X = Some "b"} 1
	  );
    s2 <- return (
	  let
	      (* build it bottom-up; may reuse expression parts for free! *)
	      val d = one_of c_digit
	      val re = capture [#Y] (repeat d (Rexactly 4))
	      val re = concat re (literal "-")
	      val re = concat re (capture [#M] (repeat d (Rexactly 2)))
	      val re = concat re (literal "-")
	      val re = concat re (capture [#D] (repeat d (Rexactly 2)))
	  in
	      match_eq re "1999-02-03" {Y = Some "1999", M = Some "02", D = Some "03"} 2
	  end);
    s3 <- return (
	  let
	      val re = capture [#Id] (plus (one_of c_word))
	      val re = concat re (literal ":")
	      val re = concat re (plus (one_of c_whitespace))
	      val re = concat re (capture [#Value] (plus (one_of c_digit)))
	  in
	      match_eq re "identifier: 12345" {Id = Some "identifier", Value = Some "12345"} 3
	  end);
    s4 <- return (
	  let
	      val re = capture [#A] (literal "a")
	      val re = concat (opt re) (literal "b")
	  in
	      match_eq re "b" {A = None} 4
	  end);
    return (s1 ^ "\n" ^ s2 ^ "\n" ^ s3 ^ "\n" ^ s4)    
    
fun groups (): transaction page =
    res <- groups_test ();
    format_results res

fun groups_client (): transaction page =
(*    format_results_client (groups_test ())*)
    return <xml>
      <head>
	<title>Test</title>
      </head>
      <body>
	<active code={r <- groups_test (); return <xml><pre>{[r]}</pre></xml>}/>
    </body>
</xml>
