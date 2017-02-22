open Tsregex

fun main (): transaction page =
    return <xml>
      <body>{[show (
		  alt (capture {X="x"} (literal "abcdef")) (concat (literal "Z") any)
	    )]}
      </body>
    </xml>
