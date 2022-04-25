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

open Core
open Ast_types
open Util.Pretty_printer

(** [Parsetree] is the abstract syntax tree produced by parsing
    Dromedary's source code. *)

type core_type =
  | Ptyp_var of string
  | Ptyp_arrow of core_type * core_type
  | Ptyp_tuple of core_type list
  | Ptyp_constr of core_type list * string
  | Ptyp_variant of row
  | Ptyp_mu of string * core_type
  | Ptyp_where of core_type * string * core_type
[@@deriving sexp_of]

and row = row_field list * closed_flag
and row_field = Row_tag of string * core_type option

and closed_flag =
  | Closed
  | Open

type core_scheme = string list * core_type [@@deriving sexp_of]

type pattern =
  | Ppat_any
  | Ppat_var of string
  | Ppat_alias of pattern * string
  | Ppat_const of constant
  | Ppat_tuple of pattern list
  | Ppat_construct of string * (string list * pattern) option
  | Ppat_variant of string * pattern option
  | Ppat_constraint of pattern * core_type
[@@deriving sexp_of]

type expression =
  | Pexp_var of string
  | Pexp_prim of primitive
  | Pexp_const of constant
  | Pexp_fun of pattern * expression
  | Pexp_app of expression * expression
  | Pexp_let of rec_flag * value_binding list * expression
  | Pexp_forall of string list * expression
  | Pexp_exists of string list * expression
  | Pexp_constraint of expression * core_type
  | Pexp_construct of string * expression option
  | Pexp_record of (string * expression) list
  | Pexp_field of expression * string
  | Pexp_tuple of expression list
  | Pexp_match of expression * case list
  | Pexp_ifthenelse of expression * expression * expression
  | Pexp_try of expression * case list
  | Pexp_sequence of expression * expression
  | Pexp_while of expression * expression
  | Pexp_for of pattern * expression * expression * direction_flag * expression
  | Pexp_variant of string * expression option
[@@deriving sexp_of]

and value_binding =
  { pvb_forall_vars : string list
  ; pvb_pat : pattern
  ; pvb_expr : expression
  }

and case =
  { pc_lhs : pattern
  ; pc_rhs : expression
  }

type value_description =
  { pval_name : string
  ; pval_type : core_scheme
  ; pval_prim : string
  }
[@@deriving sexp_of]

type type_declaration =
  { ptype_name : string
  ; ptype_params : string list
  ; ptype_kind : type_decl_kind
  }
[@@deriving sexp_of]

and type_decl_kind =
  | Ptype_variant of constructor_declaration list
  | Ptype_record of label_declaration list
  | Ptype_abstract
  | Ptype_alias of core_type

and label_declaration =
  { plabel_name : string
  ; plabel_betas : string list
  ; plabel_arg : core_type
  }

and constructor_declaration =
  { pconstructor_name : string
  ; pconstructor_arg : constructor_argument option
  ; pconstructor_constraints : (core_type * core_type) list
  }

and constructor_argument =
  { pconstructor_arg_betas : string list
  ; pconstructor_arg_type : core_type
  }

type extension_constructor =
  { pext_name : string
  ; pext_params : string list
  ; pext_kind : extension_constructor_kind
  }
[@@deriving sexp_of]

and extension_constructor_kind = Pext_decl of constructor_declaration

type structure_item =
  | Pstr_value of rec_flag * value_binding list
  | Pstr_primitive of value_description
  | Pstr_type of type_declaration list
  | Pstr_exception of type_exception
[@@deriving sexp_of]

and type_exception = { ptyexn_constructor : extension_constructor }

type structure = structure_item list [@@deriving sexp_of]

(* "Machine format" pretty prints display terms using an explicit tree structure,
   using indentations to mark new structures. 

   For example:
   {[
     val curry : Parsetree.expression

     pp_expression_mach Format.std_formatter curry;;
     Expression:
     └──Expression: Function
        └──Pattern: Variable: f
        └──Expression: Function
           └──Pattern: Variable: x
           └──Expression: Function
              └──Pattern: Variable: y
              └──Expression: Application
                 └──Expression: Variable: f
                 └──Expression: Tuple
                    └──Expression: Variable: x
                    └──Expression: Variable: y
   ]}

   This is rather useful for expect tests, etc, where an explicit tree-like
   structure is clearer (for correctness).
*)

let indent_space = "   "

let string_of_closed_flag closed_flag =
  match closed_flag with
  | Open -> "Open"
  | Closed -> "Closed"


let rec pp_core_type_mach ~indent ppf core_type =
  let print = Format.fprintf ppf "%sType: %s@." indent in
  let indent = indent_space ^ indent in
  match core_type with
  | Ptyp_var x ->
    print "Variable";
    Format.fprintf ppf "%sVariable: %s@." indent x
  | Ptyp_arrow (t1, t2) ->
    print "Arrow";
    pp_core_type_mach ~indent ppf t1;
    pp_core_type_mach ~indent ppf t2
  | Ptyp_tuple ts ->
    print "Tuple";
    List.iter ~f:(pp_core_type_mach ~indent ppf) ts
  | Ptyp_constr (ts, constr) ->
    print "Constructor";
    Format.fprintf ppf "%sConstructor: %s@." indent constr;
    List.iter ~f:(pp_core_type_mach ~indent ppf) ts
  | Ptyp_variant row ->
    print "Variant";
    pp_row_mach ~indent ppf row
  | Ptyp_mu (x, t) ->
    print "Mu";
    Format.fprintf ppf "%sVariable: %s@." indent x;
    pp_core_type_mach ~indent ppf t
  | Ptyp_where (t1, x, t2) ->
    print "Where";
    Format.fprintf ppf "%sVariable: %s@." indent x;
    pp_core_type_mach ~indent ppf t2;
    pp_core_type_mach ~indent ppf t1


and pp_row_mach ~indent ppf (row_fields, closed_flag) =
  Format.fprintf ppf "%sRow: %s@." indent (string_of_closed_flag closed_flag);
  let indent = indent_space ^ indent in
  List.iter ~f:(pp_row_field_mach ~indent ppf) row_fields


and pp_row_field_mach ~indent ppf row_field =
  let print = Format.fprintf ppf "%sRow field: %s@." indent in
  let indent = indent_space ^ indent in
  match row_field with
  | Row_tag (tag, core_type) ->
    print "Tag";
    Format.fprintf ppf "%sField tag: %s@." indent tag;
    Option.iter core_type ~f:(pp_core_type_mach ~indent ppf)


let pp_core_scheme_mach ~indent ppf (variables, core_type) =
  Format.fprintf ppf "%sScheme:@." indent;
  let indent = indent_space ^ indent in
  let variables =
    match variables with
    | [] -> "[]"
    | variables -> String.concat ~sep:"," variables
  in
  Format.fprintf ppf "%sVariables: %s@." indent variables;
  pp_core_type_mach ~indent ppf core_type


let rec pp_pattern_mach ~indent ppf pat =
  let print = Format.fprintf ppf "%sPattern: %s@." indent in
  let indent = indent_space ^ indent in
  match pat with
  | Ppat_any -> print "Any"
  | Ppat_var x -> print ("Variable: " ^ x)
  | Ppat_alias (pat, x) ->
    print "Alias";
    pp_pattern_mach ~indent ppf pat;
    Format.fprintf ppf "%sAs: %s@." indent x
  | Ppat_const const -> print ("Constant: " ^ string_of_constant const)
  | Ppat_tuple pats ->
    print "Tuple";
    List.iter ~f:(pp_pattern_mach ~indent ppf) pats
  | Ppat_construct (constr, pat) ->
    print "Construct";
    Format.fprintf ppf "%sConstructor: %s@." indent constr;
    (match pat with
    | None -> ()
    | Some (_, pat) -> pp_pattern_mach ~indent ppf pat)
  | Ppat_variant (tag, pat) ->
    print "Variant";
    Format.fprintf ppf "%sTag: %s@." indent tag;
    (match pat with
    | None -> ()
    | Some pat -> pp_pattern_mach ~indent ppf pat)
  | Ppat_constraint (pat, core_type) ->
    print "Constraint";
    pp_pattern_mach ~indent ppf pat;
    pp_core_type_mach ~indent ppf core_type


let rec pp_expression_mach ~indent ppf exp =
  let print = Format.fprintf ppf "%sExpression: %s@." indent in
  let indent = indent_space ^ indent in
  match exp with
  | Pexp_var x -> print ("Variable: " ^ x)
  | Pexp_prim prim -> print ("Primitive: " ^ string_of_primitive prim)
  | Pexp_const const -> print ("Constant: " ^ string_of_constant const)
  | Pexp_fun (pat, exp) ->
    print "Function";
    pp_pattern_mach ~indent ppf pat;
    pp_expression_mach ~indent ppf exp
  | Pexp_app (exp1, exp2) ->
    print "Application";
    pp_expression_mach ~indent ppf exp1;
    pp_expression_mach ~indent ppf exp2
  | Pexp_let (rec_flag, value_bindings, exp) ->
    print ("Let: " ^ string_of_rec_flag rec_flag);
    pp_value_bindings_mach ~indent ppf value_bindings;
    pp_expression_mach ~indent ppf exp
  | Pexp_forall (variables, exp) ->
    print "Forall";
    let variables = String.concat ~sep:"," variables in
    Format.fprintf ppf "%sVariables: %s@." indent variables;
    pp_expression_mach ~indent ppf exp
  | Pexp_exists (variables, exp) ->
    print "Exists";
    let variables = String.concat ~sep:"," variables in
    Format.fprintf ppf "%sVariables: %s@." indent variables;
    pp_expression_mach ~indent ppf exp
  | Pexp_constraint (exp, core_type) ->
    print "Constraint";
    pp_expression_mach ~indent ppf exp;
    pp_core_type_mach ~indent ppf core_type
  | Pexp_construct (constr, exp) ->
    print "Construct";
    Format.fprintf ppf "%sConstructor: %s@." indent constr;
    (match exp with
    | None -> ()
    | Some exp -> pp_expression_mach ~indent ppf exp)
  | Pexp_record label_exps ->
    print "Record";
    List.iter ~f:(pp_label_exp_mach ~indent ppf) label_exps
  | Pexp_field (exp, label) ->
    print "Field";
    pp_expression_mach ~indent ppf exp;
    Format.fprintf ppf "%sLabel: %s@." indent label
  | Pexp_tuple exps ->
    print "Tuple";
    List.iter ~f:(pp_expression_mach ~indent ppf) exps
  | Pexp_match (exp, cases) ->
    print "Match";
    pp_expression_mach ~indent ppf exp;
    Format.fprintf ppf "%sCases:@." indent;
    List.iter ~f:(pp_case_mach ~indent:(indent_space ^ indent) ppf) cases
  | Pexp_ifthenelse (exp1, exp2, exp3) ->
    print "If";
    pp_expression_mach ~indent ppf exp1;
    pp_expression_mach ~indent ppf exp2;
    pp_expression_mach ~indent ppf exp3
  | Pexp_try (exp, cases) ->
    print "Try";
    pp_expression_mach ~indent ppf exp;
    Format.fprintf ppf "%sCases:@." indent;
    List.iter ~f:(pp_case_mach ~indent:(indent_space ^ indent) ppf) cases
  | Pexp_sequence (exp1, exp2) ->
    print "Sequence";
    pp_expression_mach ~indent ppf exp1;
    pp_expression_mach ~indent ppf exp2
  | Pexp_while (exp1, exp2) ->
    print "While";
    pp_expression_mach ~indent ppf exp1;
    pp_expression_mach ~indent ppf exp2
  | Pexp_for (pat, exp1, exp2, direction_flag, exp3) ->
    print "For";
    pp_pattern_mach ~indent ppf pat;
    pp_expression_mach ~indent ppf exp1;
    Format.fprintf
      ppf
      "%sDirection: %s@."
      indent
      (string_of_direction_flag direction_flag);
    pp_expression_mach ~indent ppf exp2;
    pp_expression_mach ~indent ppf exp3
  | Pexp_variant (tag, exp) ->
    print "Variant";
    Format.fprintf ppf "%sTag: %s@." indent tag;
    (match exp with
    | None -> ()
    | Some exp -> pp_expression_mach ~indent ppf exp)


and pp_value_bindings_mach ~indent ppf value_bindings =
  Format.fprintf ppf "%sValue bindings:@." indent;
  let indent = indent_space ^ indent in
  List.iter ~f:(pp_value_binding_mach ~indent ppf) value_bindings


and pp_label_exp_mach ~indent ppf (label, exp) =
  Format.fprintf ppf "%sLabel: %s@." indent label;
  let indent = indent_space ^ indent in
  pp_expression_mach ~indent ppf exp


and pp_value_binding_mach ~indent ppf value_binding =
  Format.fprintf ppf "%sValue binding:@." indent;
  let indent = indent_space ^ indent in
  pp_pattern_mach ~indent ppf value_binding.pvb_pat;
  pp_expression_mach ~indent ppf value_binding.pvb_expr


and pp_case_mach ~indent ppf case =
  Format.fprintf ppf "%sCase:@." indent;
  let indent = indent_space ^ indent in
  pp_pattern_mach ~indent ppf case.pc_lhs;
  pp_expression_mach ~indent ppf case.pc_rhs


let pp_value_description_mach ~indent ppf value_desc =
  Format.fprintf ppf "%sValue description:@." indent;
  let indent = indent_space ^ indent in
  Format.fprintf ppf "%sName: %s@." indent value_desc.pval_name;
  pp_core_scheme_mach ~indent ppf value_desc.pval_type;
  Format.fprintf ppf "%sPrimitive name: %s@." indent value_desc.pval_prim


let pp_constraint_mach ~indent ppf (lhs, rhs) =
  Format.fprintf ppf "%sConstraint:@." indent;
  let indent = indent_space ^ indent in
  pp_core_type_mach ~indent ppf lhs;
  pp_core_type_mach ~indent ppf rhs


let pp_constructor_argument_mach ~indent ppf constr_arg =
  Format.fprintf ppf "%sConstructor argument:@." indent;
  let indent = indent_space ^ indent in
  Format.fprintf
    ppf
    "%sConstructor existentials: %s@."
    indent
    (String.concat ~sep:" " constr_arg.pconstructor_arg_betas);
  pp_core_type_mach ~indent ppf constr_arg.pconstructor_arg_type


let pp_constructor_declaration_mach ~indent ppf constr_decl =
  Format.fprintf ppf "%sConstructor declaration:@." indent;
  let indent = indent_space ^ indent in
  Format.fprintf
    ppf
    "%sConstructor name: %s@."
    indent
    constr_decl.pconstructor_name;
  (match constr_decl.pconstructor_arg with
  | None -> ()
  | Some constr_arg -> pp_constructor_argument_mach ~indent ppf constr_arg);
  List.iter
    ~f:(pp_constraint_mach ~indent ppf)
    constr_decl.pconstructor_constraints


let pp_label_declaration_mach ~indent ppf label_decl =
  Format.fprintf ppf "%sLabel declaration:@." indent;
  let indent = indent_space ^ indent in
  Format.fprintf ppf "%sLabel name: %s@." indent label_decl.plabel_name;
  Format.fprintf
    ppf
    "%sLabel polymorphic parameters: %s@."
    indent
    (String.concat ~sep:" " label_decl.plabel_betas);
  pp_core_type_mach ~indent ppf label_decl.plabel_arg


let pp_type_decl_kind_mach ~indent ppf type_decl_kind =
  let print = Format.fprintf ppf "%sType declaration kind: %s@." indent in
  let indent = indent_space ^ indent in
  match type_decl_kind with
  | Ptype_variant constr_decls ->
    print "Variant";
    List.iter constr_decls ~f:(pp_constructor_declaration_mach ~indent ppf)
  | Ptype_record label_decls ->
    print "Record";
    List.iter label_decls ~f:(pp_label_declaration_mach ~indent ppf)
  | Ptype_abstract -> print "Abstract"
  | Ptype_alias core_type ->
    print "Alias";
    pp_core_type_mach ~indent ppf core_type


let pp_type_declaration_mach ~indent ppf type_decl =
  Format.fprintf ppf "%sType declaration:@." indent;
  let indent = indent_space ^ indent in
  Format.fprintf ppf "%sType name: %s@." indent type_decl.ptype_name;
  Format.fprintf
    ppf
    "%sType parameters: %s@."
    indent
    (String.concat ~sep:" " type_decl.ptype_params);
  pp_type_decl_kind_mach ~indent ppf type_decl.ptype_kind


let pp_extension_constructor_kind_mach ~indent ppf ext_constr_kind =
  let print = Format.fprintf ppf "%sExtension constructor kind: %s@." indent in
  let indent = indent_space ^ indent in
  match ext_constr_kind with
  | Pext_decl constr_decl ->
    print "Declaration";
    pp_constructor_declaration_mach ~indent ppf constr_decl


let pp_extension_constructor_mach ~indent ppf ext_constr =
  Format.fprintf ppf "%sExtension constructor:@." indent;
  let indent = indent_space ^ indent in
  Format.fprintf ppf "%sExtension name: %s@." indent ext_constr.pext_name;
  Format.fprintf
    ppf
    "%sExtension parameters: %s@."
    indent
    (String.concat ~sep:" " ext_constr.pext_params);
  pp_extension_constructor_kind_mach ~indent ppf ext_constr.pext_kind


let pp_type_exception_mach ~indent ppf type_exn =
  Format.fprintf ppf "%sType exception:@." indent;
  let indent = indent_space ^ indent in
  pp_extension_constructor_mach ~indent ppf type_exn.ptyexn_constructor


let pp_structure_item_mach ~indent ppf str_item =
  let print = Format.fprintf ppf "%sStructure item: %s@." indent in
  let indent = indent_space ^ indent in
  match str_item with
  | Pstr_value (rec_flag, value_bindings) ->
    print ("Let: " ^ string_of_rec_flag rec_flag);
    pp_value_bindings_mach ~indent ppf value_bindings
  | Pstr_primitive value_desc ->
    print "Primitive";
    pp_value_description_mach ~indent ppf value_desc
  | Pstr_type type_decls ->
    print "Type";
    List.iter type_decls ~f:(pp_type_declaration_mach ~indent ppf)
  | Pstr_exception type_exception ->
    print "Exception";
    pp_type_exception_mach ~indent ppf type_exception


let pp_structure_mach ~indent ppf str =
  Format.fprintf ppf "%sStructure:@." indent;
  let indent = indent_space ^ indent in
  List.iter str ~f:(pp_structure_item_mach ~indent ppf)


let to_pp_mach ~name ~pp ppf t =
  Format.fprintf ppf "%s:@." name;
  let indent = "└──" in
  pp ~indent ppf t


let pp_core_type_mach = to_pp_mach ~name:"Core type" ~pp:pp_core_type_mach
let pp_core_scheme_mach = to_pp_mach ~name:"Core scheme" ~pp:pp_core_scheme_mach
let pp_pattern_mach = to_pp_mach ~name:"Pattern" ~pp:pp_pattern_mach
let pp_expression_mach = to_pp_mach ~name:"Expression" ~pp:pp_expression_mach

let pp_value_binding_mach =
  to_pp_mach ~name:"Value binding" ~pp:pp_value_binding_mach


let pp_case_mach = to_pp_mach ~name:"Case" ~pp:pp_case_mach

let pp_value_description_mach =
  to_pp_mach ~name:"Value description" ~pp:pp_value_description_mach


let pp_type_declaration_mach =
  to_pp_mach ~name:"Type declaration" ~pp:pp_type_declaration_mach


let pp_label_declaration_mach =
  to_pp_mach ~name:"Label declaration" ~pp:pp_label_declaration_mach


let pp_constructor_declaration_mach =
  to_pp_mach ~name:"Constructor declaration" ~pp:pp_constructor_declaration_mach


let pp_extension_constructor_mach =
  to_pp_mach ~name:"Extension constructor" ~pp:pp_extension_constructor_mach


let pp_structure_item_mach =
  to_pp_mach ~name:"Structure item" ~pp:pp_structure_item_mach


let pp_structure_mach = to_pp_mach ~name:"Structure" ~pp:pp_structure_mach

(* "Human format" (or standard) pretty printer display the terms using their 
   syntactic representation. This is often used in error reporting, etc.

   For example:
   {[
      val map : Parsetree.expression

      pp_expression Format.std_formatter map;;
      let rec map f xs =
        match xs with (Nil -> Nil | Cons (x, xs) -> Cons (f x, map f xs)) in
      map Nil
   ]}
*)

let rec pp_core_type ppf core_type =
  let rec loop ?(parens = false) ppf core_type =
    match core_type with
    | Ptyp_var x -> Format.fprintf ppf "%s" x
    | Ptyp_arrow (t1, t2) ->
      let pp ppf (t1, t2) =
        Format.fprintf
          ppf
          "@[%a@;->@;%a@]"
          (loop ~parens:true)
          t1
          (loop ~parens:false)
          t2
      in
      paren ~parens pp ppf (t1, t2)
    | Ptyp_tuple ts ->
      paren ~parens (list ~sep:"@;*@;" (loop ~parens:true)) ppf ts
    | Ptyp_constr (ts, constr) ->
      Format.fprintf
        ppf
        "%a@;%s"
        (list ~first:"(" ~last:")" ~sep:",@;" (loop ~parens:false))
        ts
        constr
    | Ptyp_variant row -> Format.fprintf ppf "@[[@;%a@;]@]" pp_row row
    | Ptyp_mu (x, t) -> Format.fprintf ppf "@[mu '%s.@;%a@]" x pp_core_type t
    | Ptyp_where (t1, x, t2) ->
      Format.fprintf
        ppf
        "@[%a@;where@;%s@;=@;%a@]"
        pp_core_type
        t1
        x
        pp_core_type
        t2
  in
  loop ppf core_type


and pp_row ppf (row_fields, closed_flag) =
  let closed_flag =
    match closed_flag with
    | Closed -> "<"
    | Open -> ">"
  in
  Format.fprintf
    ppf
    "%s@;%a"
    closed_flag
    (list ~sep:"@;|@;" pp_row_field)
    row_fields


and pp_row_field ppf (Row_tag (tag, core_type)) =
  Format.fprintf
    ppf
    "%s%a"
    tag
    (fun ppf -> option ~first:"@;of@;" pp_core_type ppf)
    core_type


let pp_core_scheme ppf (variables, core_type) =
  Format.fprintf
    ppf
    "@[%a@;.@;%a@]"
    (fun ppf -> list ~sep:",@;" Format.pp_print_string ppf)
    variables
    pp_core_type
    core_type


let rec pp_pattern ppf pattern =
  match pattern with
  | Ppat_any -> Format.fprintf ppf "_"
  | Ppat_var x -> Format.fprintf ppf "%s" x
  | Ppat_alias (pat, x) -> Format.fprintf ppf "@[%a@;as@;%s@]" pp_pattern pat x
  | Ppat_const const -> Format.fprintf ppf "%s" (string_of_constant const)
  | Ppat_tuple ts ->
    Format.fprintf ppf "@[(%a)@]" (fun ppf -> list ~sep:",@;" pp_pattern ppf) ts
  | Ppat_construct (constr, pat) ->
    Format.fprintf
      ppf
      "@[%s%a@]"
      constr
      (fun ppf -> option ~first:"@;" pp_pattern ppf)
      Option.(pat >>| snd)
  | Ppat_constraint (pat, core_type) ->
    Format.fprintf ppf "@[(%a@;:@;%a)@]" pp_pattern pat pp_core_type core_type
  | Ppat_variant (tag, pat) ->
    Format.fprintf
      ppf
      "@[`%s%a@]"
      tag
      (fun ppf -> option ~first:"@;" pp_pattern ppf)
      pat


let pp_let_bindings ?(flag = "") ~pp ppf bindings =
  match bindings with
  | [] -> ()
  | [ b ] -> Format.fprintf ppf "@[let %s%a@]" flag pp b
  | b :: bs ->
    Format.fprintf
      ppf
      "@[<v>let %s%a@,%a@]"
      flag
      pp
      b
      (fun ppf -> list ~sep:"@,and" pp ppf)
      bs


let rec pp_expression ppf exp =
  match exp with
  | Pexp_var x -> Format.fprintf ppf "%s" x
  | Pexp_prim prim -> Format.fprintf ppf "%%prim %s" (string_of_primitive prim)
  | Pexp_const const -> Format.fprintf ppf "%s" (string_of_constant const)
  | Pexp_fun (pat, exp) ->
    Format.fprintf ppf "@[fun@;%a->@;%a@]" pp_pattern pat pp_expression exp
  | Pexp_app (exp1, exp2) ->
    Format.fprintf ppf "@[%a@ %a@]" pp_expression exp1 pp_expression exp2
  | Pexp_let (rec_flag, value_bindings, exp) ->
    let flag =
      match rec_flag with
      | Nonrecursive -> ""
      | Recursive -> "rec "
    in
    Format.fprintf
      ppf
      "@[%a in@;%a@]"
      (fun ppf -> pp_let_bindings ~flag ~pp:pp_value_binding ppf)
      value_bindings
      pp_expression
      exp
  | Pexp_forall (variables, exp) ->
    Format.fprintf
      ppf
      "@[forall@;%a->@;%a@]"
      (fun ppf -> list ~sep:",@;" Format.pp_print_string ppf)
      variables
      pp_expression
      exp
  | Pexp_exists (variables, exp) ->
    Format.fprintf
      ppf
      "@[exists@;%a->@;%a@]"
      (fun ppf -> list ~sep:",@;" Format.pp_print_string ppf)
      variables
      pp_expression
      exp
  | Pexp_construct (constr, exp) ->
    Format.fprintf
      ppf
      "@[%s%a@]"
      constr
      (fun ppf -> option ~first:"@;" pp_expression ppf)
      exp
  | Pexp_constraint (exp, core_type) ->
    Format.fprintf
      ppf
      "@[(%a@;:@;%a)@]"
      pp_expression
      exp
      pp_core_type
      core_type
  | Pexp_record label_exps ->
    let pp ppf (label, exp) =
      Format.fprintf ppf "@[%s@;=@;%a@]" label pp_expression exp
    in
    Format.fprintf ppf "@[{%a}@]" (fun ppf -> list ~sep:",@;" pp ppf) label_exps
  | Pexp_field (exp, label) ->
    Format.fprintf ppf "@[%a.%s@]" pp_expression exp label
  | Pexp_tuple exps ->
    Format.fprintf
      ppf
      "@[(%a)@]"
      (fun ppf -> list ~sep:",@;" pp_expression ppf)
      exps
  | Pexp_match (exp, cases) ->
    Format.fprintf
      ppf
      "@[<hv>@[@[match@ %a@]@ with@]@ (%a)@]"
      pp_expression
      exp
      (fun ppf -> list ~sep:"@;|@;" pp_case ppf)
      cases
  | Pexp_ifthenelse (exp1, exp2, exp3) ->
    Format.fprintf
      ppf
      "@[(@[if@ %a@]@;@[then@ %a@]@;@[else@ %a@])@]"
      pp_expression
      exp1
      pp_expression
      exp2
      pp_expression
      exp3
  | Pexp_try (exp, cases) ->
    Format.fprintf
      ppf
      "@[<hv>@[@[try@ %a@]@ with@]@ (%a)@]"
      pp_expression
      exp
      (fun ppf -> list ~sep:"@;|@;" pp_case ppf)
      cases
  | Pexp_sequence _ ->
    let rec loop exp =
      match exp with
      | Pexp_sequence (exp1, exp2) -> exp1 :: loop exp2
      | _ -> [ exp ]
    in
    Format.fprintf
      ppf
      "@[<hv>%a@]"
      (fun ppf -> list ~sep:";@;" pp_expression ppf)
      (loop exp)
  | Pexp_while (exp1, exp2) ->
    Format.fprintf
      ppf
      "@[<2>while@;%a@;do@;%a@;done@]"
      pp_expression
      exp1
      pp_expression
      exp2
  | Pexp_for (pat, exp1, exp2, direction_flag, exp3) ->
    Format.fprintf
      ppf
      "@[<hv0>@[<hv2>@[<2>for %a =@;%a@;%s@;%a@;do@]@;%a@]@;done@]"
      pp_pattern
      pat
      pp_expression
      exp1
      (string_of_direction_flag direction_flag)
      pp_expression
      exp2
      pp_expression
      exp3
  | Pexp_variant (tag, exp) ->
    Format.fprintf
      ppf
      "@[`%s%a@]"
      tag
      (fun ppf -> option ~first:"@;" pp_expression ppf)
      exp


and pp_expression_function ppf exp =
  match exp with
  | Pexp_fun (pat, exp) ->
    Format.fprintf ppf "%a@ %a" pp_pattern pat pp_expression_function exp
  | _ -> Format.fprintf ppf "=@;%a" pp_expression exp


and pp_value_binding ppf nonrec_value_binding =
  let pat = nonrec_value_binding.pvb_pat
  and exp = nonrec_value_binding.pvb_expr in
  match pat with
  | Ppat_var x -> Format.fprintf ppf "@[%s@ %a@]" x pp_expression_function exp
  | _ -> Format.fprintf ppf "@[%a@;=@;%a@]" pp_pattern pat pp_expression exp


and pp_case ppf case =
  Format.fprintf
    ppf
    "@[%a@;->@;%a@]"
    pp_pattern
    case.pc_lhs
    pp_expression
    case.pc_rhs


let pp_constructor_argument ppf constr_arg =
  Format.fprintf
    ppf
    "@[of@;%a%a@]"
    (fun ppf -> list ~sep:"@;" ~last:".@;" Format.pp_print_string ppf)
    constr_arg.pconstructor_arg_betas
    pp_core_type
    constr_arg.pconstructor_arg_type


let pp_constraints ppf constraints =
  let pp_constraint ppf (t1, t2) =
    Format.fprintf ppf "@[%a@;=@;%a@]" pp_core_type t1 pp_core_type t2
  in
  list ~first:"constraint@;" ~sep:"@;and@;" pp_constraint ppf constraints


let pp_constructor_declaration ppf constr_decl =
  Format.fprintf
    ppf
    "@[%s%a%a@]"
    constr_decl.pconstructor_name
    (fun ppf -> option ~first:"@;" pp_constructor_argument ppf)
    constr_decl.pconstructor_arg
    pp_constraints
    constr_decl.pconstructor_constraints


let pp_label_declaration ppf label_decl =
  Format.fprintf
    ppf
    "@[%s@;:@;%a%a@]"
    label_decl.plabel_name
    (fun ppf -> list ~sep:"@;" ~last:".@;" Format.pp_print_string ppf)
    label_decl.plabel_betas
    pp_core_type
    label_decl.plabel_arg


let pp_type_decl_kind ppf type_decl_kind =
  match type_decl_kind with
  | Ptype_variant constr_decls ->
    Format.fprintf
      ppf
      "@;=@;@[<hv>%a@]"
      (fun ppf -> list ~sep:"@;|@;" pp_constructor_declaration ppf)
      constr_decls
  | Ptype_record label_decls ->
    Format.fprintf
      ppf
      "@;=@;@[<hv>{@;%a@;}@]"
      (fun ppf -> list ~sep:"@;;@;" pp_label_declaration ppf)
      label_decls
  | Ptype_abstract -> ()
  | Ptype_alias core_type -> Format.fprintf ppf "@;=@;%a" pp_core_type core_type


let pp_type_params ppf params =
  match params with
  | [] -> ()
  | [ param ] -> Format.fprintf ppf "%s@;" param
  | params ->
    list ~sep:",@;" ~first:"(" ~last:")@;" Format.pp_print_string ppf params


let pp_type_declaration ppf type_decl =
  Format.fprintf
    ppf
    "@[<hv>@[type@;%a%s@]%a@]"
    pp_type_params
    type_decl.ptype_params
    type_decl.ptype_name
    pp_type_decl_kind
    type_decl.ptype_kind


let pp_extension_constructor_kind ppf ext_constr_kind =
  match ext_constr_kind with
  | Pext_decl constr_decl -> pp_constructor_declaration ppf constr_decl


let pp_extension_constructor ppf ext_constr =
  Format.fprintf
    ppf
    "@[@[type@;%a%s@]@;+=@;%a@]"
    pp_type_params
    ext_constr.pext_params
    ext_constr.pext_name
    pp_extension_constructor_kind
    ext_constr.pext_kind


let pp_type_exception ppf { ptyexn_constructor = exn_constr } =
  assert (String.(exn_constr.pext_name = "exn"));
  assert (List.is_empty exn_constr.pext_params);
  assert (
    match exn_constr.pext_kind with
    | Pext_decl constr_decl ->
      List.is_empty constr_decl.pconstructor_constraints);
  Format.fprintf
    ppf
    "@[exception@;%a]"
    pp_extension_constructor_kind
    exn_constr.pext_kind


let pp_type_declarations ~pp ppf bindings =
  match bindings with
  | [] -> ()
  | [ b ] -> Format.fprintf ppf "@[type %a@]" pp b
  | b :: bs ->
    Format.fprintf
      ppf
      "@[<v>type %a@,%a@]"
      pp
      b
      (fun ppf -> list ~sep:"@,and" pp ppf)
      bs


let pp_structure_item ppf str_item =
  match str_item with
  | Pstr_value (rec_flag, value_bindings) ->
    let flag =
      match rec_flag with
      | Nonrecursive -> ""
      | Recursive -> "rec "
    in
    pp_let_bindings ~flag ~pp:pp_value_binding ppf value_bindings
  | Pstr_primitive value_desc ->
    Format.fprintf
      ppf
      "@[external@;%s@;:@;%a@;=@;%s@]"
      value_desc.pval_name
      pp_core_scheme
      value_desc.pval_type
      value_desc.pval_prim
  | Pstr_type type_decls ->
    let pp_type_declaration ppf type_decl =
      Format.fprintf
        ppf
        "@[<hv>@[%a%s@]@;=@;%a@]"
        pp_type_params
        type_decl.ptype_params
        type_decl.ptype_name
        pp_type_decl_kind
        type_decl.ptype_kind
    in
    pp_type_declarations ~pp:pp_type_declaration ppf type_decls
  | Pstr_exception exn -> pp_type_exception ppf exn


let pp_structure ppf str = list ~sep:"@." pp_structure_item ppf str
