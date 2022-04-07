open! Import
open Util


(* Tests from typing-gadts/name_existentials.ml
   --------------------------------------------
   Test count: 12/12
*)

let%expect_test "name-existentials-1" =
  let str = 
    {|
      type 'a ty = 
        | Int constraint 'a = int
      ;;

      type packed = 
        | Packed of 'a. 'a ty * 'a
      ;;

      external ignore : 'a. 'a -> unit = "%ignore";;

      let ok1 = 
        fun (Packed (type 'a) ((w, x) : 'a ty * 'a)) -> 
          ignore (x : 'a)
      ;;

      let ok2 = 
        exists (type 'b) ->
          fun (Packed (type 'a) ((w, x) : 'b * 'a)) -> 
            ignore (x : 'a)
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    Structure:
    └──Structure:
       └──Structure item: Type
          └──Type declaration:
             └──Type name: ty
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: Int
                   └──Constructor alphas: a
                   └──Constructor type:
                      └──Type expr: Constructor: ty
                         └──Type expr: Variable: a
                   └──Constraint:
                      └──Type expr: Variable: a
                      └──Type expr: Constructor: int
       └──Structure item: Type
          └──Type declaration:
             └──Type name: packed
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: Packed
                   └──Constructor alphas:
                   └──Constructor type:
                      └──Type expr: Constructor: packed
                   └──Constructor argument:
                      └──Constructor betas: a
                      └──Type expr: Tuple
                         └──Type expr: Constructor: ty
                            └──Type expr: Variable: a
                         └──Type expr: Variable: a
       └──Structure item: Primitive
          └──Value description:
             └──Name: ignore
             └──Scheme:
                └──Variables: a1336
                └──Type expr: Arrow
                   └──Type expr: Variable: a1336
                   └──Type expr: Constructor: unit
             └──Primitive name: %ignore
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Arrow
                      └──Type expr: Constructor: packed
                      └──Type expr: Constructor: unit
                   └──Desc: Variable: ok1
                └──Abstraction:
                   └──Variables:
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: packed
                         └──Type expr: Constructor: unit
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: packed
                            └──Desc: Construct
                               └──Constructor description:
                                  └──Name: Packed
                                  └──Constructor argument type:
                                     └──Type expr: Tuple
                                        └──Type expr: Constructor: ty
                                           └──Type expr: Variable: a1366
                                        └──Type expr: Variable: a1366
                                  └──Constructor type:
                                     └──Type expr: Constructor: packed
                               └──Pattern:
                                  └──Type expr: Tuple
                                     └──Type expr: Constructor: ty
                                        └──Type expr: Variable: a1366
                                     └──Type expr: Variable: a1366
                                  └──Desc: Tuple
                                     └──Pattern:
                                        └──Type expr: Constructor: ty
                                           └──Type expr: Variable: a1366
                                        └──Desc: Variable: w
                                     └──Pattern:
                                        └──Type expr: Variable: a1366
                                        └──Desc: Variable: x
                         └──Expression:
                            └──Type expr: Constructor: unit
                            └──Desc: Application
                               └──Expression:
                                  └──Type expr: Arrow
                                     └──Type expr: Variable: a1366
                                     └──Type expr: Constructor: unit
                                  └──Desc: Variable
                                     └──Variable: ignore
                                     └──Type expr: Variable: a1366
                               └──Expression:
                                  └──Type expr: Variable: a1366
                                  └──Desc: Variable
                                     └──Variable: x
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Arrow
                      └──Type expr: Constructor: packed
                      └──Type expr: Constructor: unit
                   └──Desc: Variable: ok2
                └──Abstraction:
                   └──Variables:
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: packed
                         └──Type expr: Constructor: unit
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: packed
                            └──Desc: Construct
                               └──Constructor description:
                                  └──Name: Packed
                                  └──Constructor argument type:
                                     └──Type expr: Tuple
                                        └──Type expr: Constructor: ty
                                           └──Type expr: Variable: a1395
                                        └──Type expr: Variable: a1395
                                  └──Constructor type:
                                     └──Type expr: Constructor: packed
                               └──Pattern:
                                  └──Type expr: Tuple
                                     └──Type expr: Constructor: ty
                                        └──Type expr: Variable: a1395
                                     └──Type expr: Variable: a1395
                                  └──Desc: Tuple
                                     └──Pattern:
                                        └──Type expr: Constructor: ty
                                           └──Type expr: Variable: a1395
                                        └──Desc: Variable: w
                                     └──Pattern:
                                        └──Type expr: Variable: a1395
                                        └──Desc: Variable: x
                         └──Expression:
                            └──Type expr: Constructor: unit
                            └──Desc: Application
                               └──Expression:
                                  └──Type expr: Arrow
                                     └──Type expr: Variable: a1395
                                     └──Type expr: Constructor: unit
                                  └──Desc: Variable
                                     └──Variable: ignore
                                     └──Type expr: Variable: a1395
                               └──Expression:
                                  └──Type expr: Variable: a1395
                                  └──Desc: Variable
                                     └──Variable: x |}]


let%expect_test "name-existentials-2" =
  let str = 
    {|
      type 'a ty = 
        | Int constraint 'a = int
      ;;

      type packed = 
        | Packed of 'a. 'a ty * 'a
      ;;

      (* OCaml fails in this case -- since we deal with existentials in a more principaled way :) *)
      let ko1 = 
        fun (Packed (type 'a) (w, x)) -> 
          ()
      ;;

      let ko1 = 
        exists (type 'b) -> 
          fun (Packed (type 'a) ((w, x) : 'b)) ->
            ()
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    Structure:
    └──Structure:
       └──Structure item: Type
          └──Type declaration:
             └──Type name: ty
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: Int
                   └──Constructor alphas: a
                   └──Constructor type:
                      └──Type expr: Constructor: ty
                         └──Type expr: Variable: a
                   └──Constraint:
                      └──Type expr: Variable: a
                      └──Type expr: Constructor: int
       └──Structure item: Type
          └──Type declaration:
             └──Type name: packed
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: Packed
                   └──Constructor alphas:
                   └──Constructor type:
                      └──Type expr: Constructor: packed
                   └──Constructor argument:
                      └──Constructor betas: a
                      └──Type expr: Tuple
                         └──Type expr: Constructor: ty
                            └──Type expr: Variable: a
                         └──Type expr: Variable: a
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Arrow
                      └──Type expr: Constructor: packed
                      └──Type expr: Constructor: unit
                   └──Desc: Variable: ko1
                └──Abstraction:
                   └──Variables:
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: packed
                         └──Type expr: Constructor: unit
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: packed
                            └──Desc: Construct
                               └──Constructor description:
                                  └──Name: Packed
                                  └──Constructor argument type:
                                     └──Type expr: Tuple
                                        └──Type expr: Constructor: ty
                                           └──Type expr: Variable: a1426
                                        └──Type expr: Variable: a1426
                                  └──Constructor type:
                                     └──Type expr: Constructor: packed
                               └──Pattern:
                                  └──Type expr: Tuple
                                     └──Type expr: Constructor: ty
                                        └──Type expr: Variable: a1426
                                     └──Type expr: Variable: a1426
                                  └──Desc: Tuple
                                     └──Pattern:
                                        └──Type expr: Constructor: ty
                                           └──Type expr: Variable: a1426
                                        └──Desc: Variable: w
                                     └──Pattern:
                                        └──Type expr: Variable: a1426
                                        └──Desc: Variable: x
                         └──Expression:
                            └──Type expr: Constructor: unit
                            └──Desc: Constant: ()
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Arrow
                      └──Type expr: Constructor: packed
                      └──Type expr: Constructor: unit
                   └──Desc: Variable: ko1
                └──Abstraction:
                   └──Variables: a1447,a1447,a1447
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: packed
                         └──Type expr: Constructor: unit
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: packed
                            └──Desc: Construct
                               └──Constructor description:
                                  └──Name: Packed
                                  └──Constructor argument type:
                                     └──Type expr: Tuple
                                        └──Type expr: Constructor: ty
                                           └──Type expr: Variable: a1447
                                        └──Type expr: Variable: a1447
                                  └──Constructor type:
                                     └──Type expr: Constructor: packed
                               └──Pattern:
                                  └──Type expr: Tuple
                                     └──Type expr: Constructor: ty
                                        └──Type expr: Variable: a1447
                                     └──Type expr: Variable: a1447
                                  └──Desc: Tuple
                                     └──Pattern:
                                        └──Type expr: Constructor: ty
                                           └──Type expr: Variable: a1447
                                        └──Desc: Variable: w
                                     └──Pattern:
                                        └──Type expr: Variable: a1447
                                        └──Desc: Variable: x
                         └──Expression:
                            └──Type expr: Constructor: unit
                            └──Desc: Constant: () |}]


let%expect_test "name-existentials-3" =
  let str = 
    {|
      type 'a ty = 
        | Int constraint 'a = int
      ;;

      type packed = 
        | Packed of 'a. 'a ty * 'a
      ;;

      external ignore : 'a. 'a -> unit = "%ignore";;

      let ko2 = 
        fun (Packed (type 'a 'b) ((a, x) : 'a ty * 'b)) ->
          ignore (x : 'b)
      ;;
    |}
  in
  print_infer_result str;
  [%expect {| "Constructor existential variable mistmatch with definition" |}]

let%expect_test "name-existentials-4" =
  let str = 
    {|
      type u = 
        | C of 'a 'b. 'a * ('a -> 'b list)
      ;;

      external ignore : 'a. 'a -> unit = "%ignore";;

      let f = 
        exists (type 'c) ->
          fun (C (type 'a 'b) ((x, f) : 'c * ('a -> 'b list))) ->
            ignore (x : 'a)
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    Structure:
    └──Structure:
       └──Structure item: Type
          └──Type declaration:
             └──Type name: u
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: C
                   └──Constructor alphas:
                   └──Constructor type:
                      └──Type expr: Constructor: u
                   └──Constructor argument:
                      └──Constructor betas: a b
                      └──Type expr: Tuple
                         └──Type expr: Variable: a
                         └──Type expr: Arrow
                            └──Type expr: Variable: a
                            └──Type expr: Constructor: list
                               └──Type expr: Variable: b
       └──Structure item: Primitive
          └──Value description:
             └──Name: ignore
             └──Scheme:
                └──Variables: a1455
                └──Type expr: Arrow
                   └──Type expr: Variable: a1455
                   └──Type expr: Constructor: unit
             └──Primitive name: %ignore
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Arrow
                      └──Type expr: Constructor: u
                      └──Type expr: Constructor: unit
                   └──Desc: Variable: f
                └──Abstraction:
                   └──Variables: a1491,a1491,a1491,a1491
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: u
                         └──Type expr: Constructor: unit
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: u
                            └──Desc: Construct
                               └──Constructor description:
                                  └──Name: C
                                  └──Constructor argument type:
                                     └──Type expr: Tuple
                                        └──Type expr: Variable: a1491
                                        └──Type expr: Arrow
                                           └──Type expr: Variable: a1491
                                           └──Type expr: Constructor: list
                                              └──Type expr: Variable: a1493
                                  └──Constructor type:
                                     └──Type expr: Constructor: u
                               └──Pattern:
                                  └──Type expr: Tuple
                                     └──Type expr: Variable: a1491
                                     └──Type expr: Arrow
                                        └──Type expr: Variable: a1491
                                        └──Type expr: Constructor: list
                                           └──Type expr: Variable: a1493
                                  └──Desc: Tuple
                                     └──Pattern:
                                        └──Type expr: Variable: a1491
                                        └──Desc: Variable: x
                                     └──Pattern:
                                        └──Type expr: Arrow
                                           └──Type expr: Variable: a1491
                                           └──Type expr: Constructor: list
                                              └──Type expr: Variable: a1493
                                        └──Desc: Variable: f
                         └──Expression:
                            └──Type expr: Constructor: unit
                            └──Desc: Application
                               └──Expression:
                                  └──Type expr: Arrow
                                     └──Type expr: Variable: a1491
                                     └──Type expr: Constructor: unit
                                  └──Desc: Variable
                                     └──Variable: ignore
                                     └──Type expr: Variable: a1491
                               └──Expression:
                                  └──Type expr: Variable: a1491
                                  └──Desc: Variable
                                     └──Variable: x |}]

let%expect_test "name-existentials-5" =
  let str = 
    {|
      type u = 
        | C of 'a 'b. 'a * ('a -> 'b list)
      ;;

      external ignore : 'a. 'a -> unit = "%ignore";;

      let f = 
        fun (C (type 'a) ((x, f) : 'a * ('a -> 'a list))) ->
          ignore (x : 'a)
      ;;
    |}
  in
  print_infer_result str;
  [%expect {| "Constructor existential variable mistmatch with definition" |}]

let%expect_test "name-existentials-6" =
  let str = 
    {|
      type 'a expr = 
        | Int of int constraint 'a = int
        | Add constraint 'a = int -> int -> int
        | App of 'arg. ('arg -> 'a) expr * 'arg expr
      ;;

      let rec (type 'a) eval = 
        fun (t : 'a expr) -> 
          ( exists (type 'b) ->
              match t with
              ( Int n -> n 
              | Add -> fun x y -> x + y
              | App (type 'arg) ((f, x) : 'b * 'arg expr) -> eval f (eval x : 'arg)
              )
          : 'a)
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    Structure:
    └──Structure:
       └──Structure item: Type
          └──Type declaration:
             └──Type name: expr
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: Int
                   └──Constructor alphas: a
                   └──Constructor type:
                      └──Type expr: Constructor: expr
                         └──Type expr: Variable: a
                   └──Constructor argument:
                      └──Constructor betas:
                      └──Type expr: Constructor: int
                   └──Constraint:
                      └──Type expr: Variable: a
                      └──Type expr: Constructor: int
                └──Constructor declaration:
                   └──Constructor name: Add
                   └──Constructor alphas: a
                   └──Constructor type:
                      └──Type expr: Constructor: expr
                         └──Type expr: Variable: a
                   └──Constraint:
                      └──Type expr: Variable: a
                      └──Type expr: Arrow
                         └──Type expr: Constructor: int
                         └──Type expr: Arrow
                            └──Type expr: Constructor: int
                            └──Type expr: Constructor: int
                └──Constructor declaration:
                   └──Constructor name: App
                   └──Constructor alphas: a
                   └──Constructor type:
                      └──Type expr: Constructor: expr
                         └──Type expr: Variable: a
                   └──Constructor argument:
                      └──Constructor betas: arg
                      └──Type expr: Tuple
                         └──Type expr: Constructor: expr
                            └──Type expr: Arrow
                               └──Type expr: Variable: arg
                               └──Type expr: Variable: a
                         └──Type expr: Constructor: expr
                            └──Type expr: Variable: arg
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Variable: eval
                └──Abstraction:
                   └──Variables: a1511
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: expr
                            └──Type expr: Variable: a1528
                         └──Type expr: Variable: a1528
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: expr
                               └──Type expr: Variable: a1528
                            └──Desc: Variable: t
                         └──Expression:
                            └──Type expr: Variable: a1528
                            └──Desc: Match
                               └──Expression:
                                  └──Type expr: Constructor: expr
                                     └──Type expr: Variable: a1528
                                  └──Desc: Variable
                                     └──Variable: t
                               └──Type expr: Constructor: expr
                                  └──Type expr: Variable: a1528
                               └──Cases:
                                  └──Case:
                                     └──Pattern:
                                        └──Type expr: Constructor: expr
                                           └──Type expr: Variable: a1528
                                        └──Desc: Construct
                                           └──Constructor description:
                                              └──Name: Int
                                              └──Constructor argument type:
                                                 └──Type expr: Constructor: int
                                              └──Constructor type:
                                                 └──Type expr: Constructor: expr
                                                    └──Type expr: Variable: a1528
                                           └──Pattern:
                                              └──Type expr: Constructor: int
                                              └──Desc: Variable: n
                                     └──Expression:
                                        └──Type expr: Variable: a1528
                                        └──Desc: Variable
                                           └──Variable: n
                                  └──Case:
                                     └──Pattern:
                                        └──Type expr: Constructor: expr
                                           └──Type expr: Variable: a1528
                                        └──Desc: Construct
                                           └──Constructor description:
                                              └──Name: Add
                                              └──Constructor type:
                                                 └──Type expr: Constructor: expr
                                                    └──Type expr: Variable: a1528
                                     └──Expression:
                                        └──Type expr: Variable: a1528
                                        └──Desc: Function
                                           └──Pattern:
                                              └──Type expr: Constructor: int
                                              └──Desc: Variable: x
                                           └──Expression:
                                              └──Type expr: Arrow
                                                 └──Type expr: Constructor: int
                                                 └──Type expr: Constructor: int
                                              └──Desc: Function
                                                 └──Pattern:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Variable: y
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Application
                                                       └──Expression:
                                                          └──Type expr: Arrow
                                                             └──Type expr: Constructor: int
                                                             └──Type expr: Constructor: int
                                                          └──Desc: Application
                                                             └──Expression:
                                                                └──Type expr: Arrow
                                                                   └──Type expr: Constructor: int
                                                                   └──Type expr: Arrow
                                                                      └──Type expr: Constructor: int
                                                                      └──Type expr: Constructor: int
                                                                └──Desc: Primitive: (+)
                                                             └──Expression:
                                                                └──Type expr: Constructor: int
                                                                └──Desc: Variable
                                                                   └──Variable: x
                                                       └──Expression:
                                                          └──Type expr: Constructor: int
                                                          └──Desc: Variable
                                                             └──Variable: y
                                  └──Case:
                                     └──Pattern:
                                        └──Type expr: Constructor: expr
                                           └──Type expr: Variable: a1528
                                        └──Desc: Construct
                                           └──Constructor description:
                                              └──Name: App
                                              └──Constructor argument type:
                                                 └──Type expr: Tuple
                                                    └──Type expr: Constructor: expr
                                                       └──Type expr: Arrow
                                                          └──Type expr: Variable: a1603
                                                          └──Type expr: Variable: a1528
                                                    └──Type expr: Constructor: expr
                                                       └──Type expr: Variable: a1603
                                              └──Constructor type:
                                                 └──Type expr: Constructor: expr
                                                    └──Type expr: Variable: a1528
                                           └──Pattern:
                                              └──Type expr: Tuple
                                                 └──Type expr: Constructor: expr
                                                    └──Type expr: Arrow
                                                       └──Type expr: Variable: a1603
                                                       └──Type expr: Variable: a1528
                                                 └──Type expr: Constructor: expr
                                                    └──Type expr: Variable: a1603
                                              └──Desc: Tuple
                                                 └──Pattern:
                                                    └──Type expr: Constructor: expr
                                                       └──Type expr: Arrow
                                                          └──Type expr: Variable: a1603
                                                          └──Type expr: Variable: a1528
                                                    └──Desc: Variable: f
                                                 └──Pattern:
                                                    └──Type expr: Constructor: expr
                                                       └──Type expr: Variable: a1603
                                                    └──Desc: Variable: x
                                     └──Expression:
                                        └──Type expr: Variable: a1528
                                        └──Desc: Application
                                           └──Expression:
                                              └──Type expr: Arrow
                                                 └──Type expr: Variable: a1603
                                                 └──Type expr: Variable: a1528
                                              └──Desc: Application
                                                 └──Expression:
                                                    └──Type expr: Arrow
                                                       └──Type expr: Constructor: expr
                                                          └──Type expr: Arrow
                                                             └──Type expr: Variable: a1603
                                                             └──Type expr: Variable: a1528
                                                       └──Type expr: Arrow
                                                          └──Type expr: Variable: a1603
                                                          └──Type expr: Variable: a1528
                                                    └──Desc: Variable
                                                       └──Variable: eval
                                                       └──Type expr: Arrow
                                                          └──Type expr: Variable: a1603
                                                          └──Type expr: Variable: a1528
                                                 └──Expression:
                                                    └──Type expr: Constructor: expr
                                                       └──Type expr: Arrow
                                                          └──Type expr: Variable: a1603
                                                          └──Type expr: Variable: a1528
                                                    └──Desc: Variable
                                                       └──Variable: f
                                           └──Expression:
                                              └──Type expr: Variable: a1603
                                              └──Desc: Application
                                                 └──Expression:
                                                    └──Type expr: Arrow
                                                       └──Type expr: Constructor: expr
                                                          └──Type expr: Variable: a1603
                                                       └──Type expr: Variable: a1603
                                                    └──Desc: Variable
                                                       └──Variable: eval
                                                       └──Type expr: Variable: a1603
                                                 └──Expression:
                                                    └──Type expr: Constructor: expr
                                                       └──Type expr: Variable: a1603
                                                    └──Desc: Variable
                                                       └──Variable: x |}]

let%expect_test "name-existentials-7" =
  let str = 
    {|
      type 'a expr = 
        | Int of int constraint 'a = int
        | Add constraint 'a = int -> int -> int
        | App of 'arg. ('arg -> 'a) expr * 'arg expr
      ;;

      let rec (type 'a) test = 
        fun (t : 'a expr) -> 
          ( exists (type 'b) ->
              match t with
              ( Int (type 'c) (n : 'c) -> n 
              | Add -> fun x y -> x + y
              | App (type 'arg) ((f, x) : ('arg -> 'a) expr * 'b) -> test f (test x : 'arg)
              )
          : 'a)
      ;;
    |}
  in
  print_infer_result str;
  [%expect {| "Constructor existential variable mistmatch with definition" |}]

let%expect_test "name-existentials-8" =
  let str = 
    {|
      type 'a option =
        | None
        | Some of 'a
      ;;

      let () = 
        match None with
        ( None (type 'a) (_ : 'a * int) -> ()
        | Some _ -> ()
        ) 
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    ("Constructor argument mismatch in pattern"
     (pat
      (Ppat_construct None
       (((a)
         (Ppat_constraint Ppat_any
          (Ptyp_tuple ((Ptyp_var a) (Ptyp_constr () int))))))))) |}]

let%expect_test "name-existentials-9" =
  let str = 
    {|
      type 'a option =
        | None
        | Some of 'a
      ;;

      let () = 
        match None with
        ( None _ -> ()
        | Some _ -> ()
        )
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    ("Constructor argument mismatch in pattern"
     (pat (Ppat_construct None ((() Ppat_any))))) |}]

let%expect_test "name-existentials-10" =
  let str = 
    {|
      type ('a, 'b) pair = Pair of 'a * 'b;;

      let f = 
        exists (type 'b) ->
          fun (Pair ((x, y) : int * 'b)) -> x + y
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    Structure:
    └──Structure:
       └──Structure item: Type
          └──Type declaration:
             └──Type name: pair
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: Pair
                   └──Constructor alphas: a b
                   └──Constructor type:
                      └──Type expr: Constructor: pair
                         └──Type expr: Variable: a
                         └──Type expr: Variable: b
                   └──Constructor argument:
                      └──Constructor betas:
                      └──Type expr: Tuple
                         └──Type expr: Variable: a
                         └──Type expr: Variable: b
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Arrow
                      └──Type expr: Constructor: pair
                         └──Type expr: Constructor: int
                         └──Type expr: Constructor: int
                      └──Type expr: Constructor: int
                   └──Desc: Variable: f
                └──Abstraction:
                   └──Variables:
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: pair
                            └──Type expr: Constructor: int
                            └──Type expr: Constructor: int
                         └──Type expr: Constructor: int
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: pair
                               └──Type expr: Constructor: int
                               └──Type expr: Constructor: int
                            └──Desc: Construct
                               └──Constructor description:
                                  └──Name: Pair
                                  └──Constructor argument type:
                                     └──Type expr: Tuple
                                        └──Type expr: Constructor: int
                                        └──Type expr: Constructor: int
                                  └──Constructor type:
                                     └──Type expr: Constructor: pair
                                        └──Type expr: Constructor: int
                                        └──Type expr: Constructor: int
                               └──Pattern:
                                  └──Type expr: Tuple
                                     └──Type expr: Constructor: int
                                     └──Type expr: Constructor: int
                                  └──Desc: Tuple
                                     └──Pattern:
                                        └──Type expr: Constructor: int
                                        └──Desc: Variable: x
                                     └──Pattern:
                                        └──Type expr: Constructor: int
                                        └──Desc: Variable: y
                         └──Expression:
                            └──Type expr: Constructor: int
                            └──Desc: Application
                               └──Expression:
                                  └──Type expr: Arrow
                                     └──Type expr: Constructor: int
                                     └──Type expr: Constructor: int
                                  └──Desc: Application
                                     └──Expression:
                                        └──Type expr: Arrow
                                           └──Type expr: Constructor: int
                                           └──Type expr: Arrow
                                              └──Type expr: Constructor: int
                                              └──Type expr: Constructor: int
                                        └──Desc: Primitive: (+)
                                     └──Expression:
                                        └──Type expr: Constructor: int
                                        └──Desc: Variable
                                           └──Variable: x
                               └──Expression:
                                  └──Type expr: Constructor: int
                                  └──Desc: Variable
                                     └──Variable: y |}]