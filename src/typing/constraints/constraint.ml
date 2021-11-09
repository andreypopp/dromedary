(*****************************************************************************)
(*                                                                           *)
(*                                Dromedary                                  *)
(*                                                                           *)
(*                Alistair O'Brien, University of Cambridge                  *)
(*                                                                           *)
(* Copyright 2021 Alistair O'Brien.                                          *)
(*                                                                           *)
(* All rights reserved. This file is distributed under the terms of the MIT  *)
(* license, as described in the file LICENSE.                                *)
(*                                                                           *)
(*****************************************************************************)

open Base
open Intf

(* ------------------------------------------------------------------------- *)

(* Include module types and type definitions from the [_intf] file. *)

include Constraint_intf

(* ------------------------------------------------------------------------- *)

module Make : Make_S = functor (Term_var : Term_var) (Types : Types) -> struct

(* ------------------------------------------------------------------------- *)

(* Add relevant modules from [Types]. *)

module Type_var = Types.Var
module Type_former = Types.Former

module Output_type = Types.Type

(* ------------------------------------------------------------------------- *)

(* The type [variable] in constraints. *)

type variable = int

(* See: https://github.com/janestreet/base/issues/121 *)
let post_incr r =
  let result = !r in
  Int.incr r;
  result

let fresh = 
  let next = ref 0 in
  fun () ->
    post_incr next

(* ------------------------------------------------------------------------- *)

(* A concrete representation of types using constraint variables.
   It is the free monad of the functor [Type_former.t] with variables
   [variable].

   While previously, we have stated that such a construct is unweidly, 
   using this provides a richer interface between constraints and the
   rest of the type checker. 

   Moreover, this provides a nicer translation between constraints 
   and "graphic types".

   Graphic type nodes consist of a "structure", either a variable
   of a type former (isomorphic to what we define below, given
   a mapping between constraint variables and graphic nodes.) *)

module Type = struct

  type t = 
    | Var of variable
    | Form of t Type_former.t 

  let var x = Var x

  let form f = Form f

end

(* ------------------------------------------------------------------------- *)

(* The empty. Used for [Cst_false], which denotes a constraint that
   is never statisfied => has no defined value. *)
type empty = |

(* ['a t] is a constraint with value type ['a]. *)
type _ t =
  | Cst_true : unit t 
  (** [true] *)
  | Cst_false : empty t 
  (** [false] *)
  | Cst_conj : 'a t * 'b t -> ('a * 'b) t 
  (** [C1 && C2] *)
  | Cst_eq : Type.t * Type.t -> unit t 
  (** [t1 =  t2] *)
  | Cst_exist : variable list * 'a t -> 'a t 
  (** [exists a. C] *)
  | Cst_forall : variable list * 'a t -> 'a t 
  (** [forall a. C] *)
  | Cst_instance : Term_var.t * Type.t -> Output_type.t list t 
  (** [x <= t] *)
  | Cst_def : def_binding list * 'a t -> 'a t
  (** [def x1 : t1 and ... and xn : tn in C] *)
  | Cst_let : 'a let_binding * 'b t -> (term_binding list * 'a bound * 'b) t
  (** [let a1 ... am [C]. (x1 : t1 and ... xk : tk) in C']. *)
  | Cst_map : 'a t * ('a -> 'b) -> 'b t 
  (** [map C f]. *)
  | Cst_match : 'a t * 'b case list -> ('a * 'b list) t
  (** [match C with (... | (x1 : t1 ... xn : tn) -> Ci | ...)]. *)

and term_binding = Term_var.t * Types.scheme

and binding = Term_var.t * Type.t

and def_binding = binding

and 'a scheme = 
  { csch_flexible_vars : variable list
  ; csch_rigid_vars : variable list
  ; csch_cst : 'a t
  }

and 'a let_binding =
  { clb_sch : 'a scheme
  ; clb_bs : binding list
  }

and 'a bound = Type_var.t list * 'a

and 'a case =
  { ccase_bs : binding list
  ; ccase_cst : 'a t
  }  

(* ------------------------------------------------------------------------- *)

(* Constraints ['a t] form an applicative functor. *)

let return x = Cst_map (Cst_true, fun () -> x)

let map t ~f = Cst_map (t, f)

let (>>|) t f = map t ~f

let both t1 t2 = Cst_conj (t1, t2)

module Let_syntax = struct
  let return = return
  let map = map
  let both = both
end

(* ------------------------------------------------------------------------- *)

(* The function [&~] is an infix alias for [both] *)

let (&~) = both

(* The function [>>] constructs a constraint from [t1] and [t2], 
   returning the value of [t2]. *)

let (>>) t1 t2 = (t1 &~ t2) >>| snd


let ( =~ ) typ1 typ2 = Cst_eq (typ1, typ2)

let inst var typ = Cst_instance (var, typ)

(* ------------------------------------------------------------------------- *)

(* Quantifiers *)


let existsn n f = 
  let vars = List.init n ~f:(fun _ -> fresh ()) in
  let cst = f vars in
  match cst with
  | Cst_exist (vars', cst) -> Cst_exist (vars @ vars', cst)
  | _ -> Cst_exist (vars, cst)

let exists1 f = 
  existsn 1 (fun vars -> f (List.hd_exn vars))

let foralln n f = 
  let vars = List.init n ~f:(fun _ -> fresh ()) in
  let cst = f vars in
  match cst with
  | Cst_forall (vars', cst) -> Cst_forall (vars @ vars', cst)
  | _ -> Cst_forall (vars, cst)

let forall1 f = 
  foralln 1 (fun vars -> f (List.hd_exn vars))
  
(* ------------------------------------------------------------------------- *)

(* Environmental constraints (binders) *)


let (#=) x typ : binding = (x, typ)

let def bindings cst = Cst_def (bindings, cst)

let scheme csch_rigid_vars csch_flexible_vars csch_cst
  = { csch_rigid_vars; csch_flexible_vars; csch_cst }

let let_ m n f1 bindings cst2 = 
  (* Initialize [m] rigid variables and [n] flexible variables. *)
  let rigid_vars = List.init m ~f:(fun _ -> fresh ()) 
  and flexible_vars = List.init n ~f:(fun _ -> fresh ()) in
  (* Pass these variables to the [bindings] function and the 
     first constraint *)
  let cst1 = f1 rigid_vars flexible_vars in
  let bindings = bindings rigid_vars flexible_vars in
  (* Build let constraint. *)
  let sch = scheme rigid_vars flexible_vars cst1 in
  Cst_let ({ clb_sch = sch; clb_bs = bindings} , cst2)

end 




(* 
TODO: Investigate the feasibility of using a dependent list:


module Dependent_list (T : sig type _ t end) = struct

  type _ t =
    | [] : unit t
    | (::) : 't T.t * 'ts t -> ('t * 'ts) t 


end 

Would require usage of the recursive module type-only trick:

module rec M : sig ... end = M 
and M_list : sig ... end = Dependent_list (M)

Some more dependent type tricks could be used to improve combinators. 
E.g. adding vectors to quantifiers for variables allows for well-typed
[Q a1 ... an. C].
*)
