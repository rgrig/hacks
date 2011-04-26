open Printf
open Scanf

type formula = 
    And of formula list 
  | Or of formula list 
  | Not of formula
  | Var of int

let (>>=) xs f = List.concat (List.map f xs)

let mkNot = function
  | Not f -> f
  | f -> Not f
let rec expandOr = function
  | Or xs -> xs >>= expandOr
  | x -> [x]
let rec expandAnd = function
  | And xs -> xs >>= expandAnd
  | x -> [x]
let mkOr xs = Or (xs >>= expandOr)
let mkAnd xs = And (xs >>= expandAnd)
let mkImply a b = mkOr [mkNot a; b]
let mkExply a b = mkImply b a
let mkVar x = 
  if x > 0 then Var x else if x < 0 then Not(Var(-x)) else
  failwith "Var can't be 0."

let lastVar = ref 0
let fresh () = incr lastVar; !lastVar

let rec cnf = function
  | And ws ->
      let v = fresh () in
      let r = List.map cnf ws in
      let ws, cnfs = List.split r in
      let cnfs = List.concat cnfs in
      (v, (v :: List.map (fun x-> -x) ws) :: List.map (fun w->[-v;w]) ws @ cnfs)
  | Or ws ->
      let v = fresh () in
      let r = List.map cnf ws in
      let ws, cnfs = List.split r in
      let cnfs = List.concat cnfs in
      (v, (-v :: ws) :: List.map (fun w->[-w;v]) ws @ cnfs)
  | Not f ->
      let v = fresh () in
      let v', cnfs = cnf f in
      (v, [v;v']::[-v;-v']::cnfs)
  | Var x -> (x, [])

let print_clause ls = 
  List.iter (fun l -> printf "%d " l) ls;
  printf "0\n"
let print_cnf =
  List.iter print_clause

let rec read_clause () =
  let x = scanf "%d " (fun x->x) in
  if x <> 0 then x :: read_clause () else []

let read_dimacs () = 
  scanf "p cnf %d %d " (fun _ _->());
  let r = ref [] in
  try
    while true do r := read_clause () :: !r done; []
  with End_of_file -> !r

let formula cnf = mkAnd (List.map (fun c -> mkOr (List.map mkVar c)) cnf)

let rec shift n = function
  | And xs -> And (List.map (shift n) xs)
  | Or xs -> Or (List.map (shift n) xs)
  | Not x -> Not (shift n x)
  | Var x ->
      if x > 0 then Var (x + n)
      else if x < 0 then Var (x - n)
      else failwith "Zero var?"

let rec max_var_rec m = function
  | And xs 
  | Or xs -> List.fold_left max m (List.map max_var xs)
  | Not x -> max m (max_var x)
  | Var x -> max m (abs x)
and max_var f = max_var_rec 0 f

let rec imp k n = 
  if k > n then [] else mkImply (Var(k+n)) (Var k) :: imp (k+1) n

let _ =
  let k = 
    if Array.length Sys.argv <> 2 then 1 
    else sscanf Sys.argv.(1) "%d" (fun x->x) in
  let phi = formula (read_dimacs ()) in
  let n = max_var phi in
  let phi' = shift n phi in
  let f = mkAnd [Var k; Var(-n-k); mkImply phi (mkAnd (phi'::imp 1 n))] in
  lastVar := n + n;
  let v, c = cnf f in
  printf "p cnf %d %d\n" !lastVar (1 + List.length c);
  printf "a "; for v = 1 to n do if v <> k then printf "%d " v done; printf "0\n";
  printf "e "; for v = n+1 to !lastVar do if v <> n+k then printf "%d " v done; printf "0\n";
  print_cnf c;
  printf "%d 0\n" v
