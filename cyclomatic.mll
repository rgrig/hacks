{
  open Printf;;
  type token_type = ID of string | LP | RP | LB | RB | SEMI | BRANCH;;

}

let ws     = [' ' '\t' '\n' '\r']*
let letter = ['a'-'z'] | ['A'-'Z'] | '_'
let digit  = ['0'-'9']
let alpha  = letter | digit
let simple_indent = letter alpha*
let indent = simple_indent | (simple_indent ws "::" ws simple_indent)

rule read_token = parse
    '('    { LP }
  | ')'    { RP }
  | '{'    { LB }
  | '}'    { RB }
  | ';'    { SEMI }
  | "\\\"" { read_token lexbuf }
  | '\"'   { in_string lexbuf }
  | "//"[^ '\n']* { read_token lexbuf }
  | '#' [^ '\n']* { read_token lexbuf }
  | "/*"   { in_comment lexbuf }
  | "if" | "else" | "for" | "while" | "case" | "FOR"
	   { BRANCH }
  | '@'indent { read_token lexbuf }
  | indent { ID (Lexing.lexeme lexbuf) }
  | eof    { raise End_of_file }
  | _      { read_token lexbuf }
      
and in_string = parse
    "\\\""  { in_string lexbuf }
  | '\"'    { read_token lexbuf }
  | eof     { prerr_endline "EOF in string"; raise End_of_file }
  | _       { in_string lexbuf }

and in_comment = parse
    "*/" { read_token lexbuf }
  | eof  { prerr_endline "EOF in comment"; raise End_of_file }
  | _    { in_comment lexbuf }

{

  let lex = Lexing.from_channel stdin;;
  let token () = read_token lex;;
  let fun_name = ref "";;
  let fun_cnt = ref 0;;

  let rec wait_fun_begin () = match token () with
      ID id -> (fun_name := id; wait_params_begin ())
    | _ -> wait_fun_begin ()
	
  and wait_params_begin () = match token () with 
      LP -> wait_params_end 1
    | ID id -> (fun_name := id; wait_params_begin ())
    | _ -> wait_fun_begin ()

  and wait_params_end = function
      0 -> wait_body_begin ()
    | n ->
	match token () with
	    LP -> wait_params_end (succ n)
	  | RP -> wait_params_end (pred n)
	  | _ -> wait_params_end n

  and wait_body_begin () = match token () with
      LB -> (fun_cnt := 1; wait_body_end 1)
    | SEMI -> wait_fun_begin ()
    | _ -> wait_body_begin ()

  and wait_body_end = function
      0 -> (printf "%4d %s\n" !fun_cnt !fun_name; wait_fun_begin ())
    | n -> 
	match token () with
	    LB -> wait_body_end (succ n)
	  | RB -> wait_body_end (pred n)
	  | BRANCH -> (incr fun_cnt; wait_body_end n)
	  | _ -> wait_body_end n
  ;;

	
  try
    wait_fun_begin ()
  with End_of_file -> () (* Normal finish *)

	  
}
