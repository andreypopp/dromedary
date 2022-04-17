open! Import
open Util

let%expect_test "" = 
  let str = 
    {|
      type ab = A | B;;

      type mab = ab;;
      type 'a t = 
        | Ab constraint 'a = ab
        | Mab constraint 'a = mab
      ;;

      let ab = Ab;;

      let (type 't) f =
        fun (t1 : 't t) (t2 : 't t) (x : 't) ->
          match (t1, t2) with
          ( (Ab, Ab) -> match x with ( A -> 1 )
          | (Mab, _) -> match x with ( A -> 2 )
          | (_, Ab) -> match x with ( B -> 3 )
          | (_, Mab) -> match x with ( B -> 4 )
          )
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    Structure:
    └──Structure:
       └──Structure item: Type
          └──Type declaration:
             └──Type name: ab
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: A
                   └──Constructor alphas:
                   └──Constructor type:
                      └──Type expr: Constructor: ab
                └──Constructor declaration:
                   └──Constructor name: B
                   └──Constructor alphas:
                   └──Constructor type:
                      └──Type expr: Constructor: ab
       └──Structure item: Type
          └──Type declaration:
             └──Type name: mab
             └──Type declaration kind: Alias
                └──Alias
                   └──Alias name: mab
                   └──Alias alphas:
                   └──Type expr: Constructor: ab
       └──Structure item: Type
          └──Type declaration:
             └──Type name: t
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: Ab
                   └──Constructor alphas: 14744
                   └──Constructor type:
                      └──Type expr: Constructor: t
                         └──Type expr: Variable: 14744
                   └──Constraint:
                      └──Type expr: Variable: 14744
                      └──Type expr: Constructor: ab
                └──Constructor declaration:
                   └──Constructor name: Mab
                   └──Constructor alphas: 14744
                   └──Constructor type:
                      └──Type expr: Constructor: t
                         └──Type expr: Variable: 14744
                   └──Constraint:
                      └──Type expr: Variable: 14744
                      └──Type expr: Constructor: mab
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Constructor: t
                      └──Type expr: Constructor: ab
                   └──Desc: Variable: ab
                └──Abstraction:
                   └──Variables:
                   └──Expression:
                      └──Type expr: Constructor: t
                         └──Type expr: Constructor: ab
                      └──Desc: Construct
                         └──Constructor description:
                            └──Name: Ab
                            └──Constructor type:
                               └──Type expr: Constructor: t
                                  └──Type expr: Constructor: ab
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Arrow
                      └──Type expr: Constructor: t
                         └──Type expr: Variable: 14764
                      └──Type expr: Arrow
                         └──Type expr: Constructor: t
                            └──Type expr: Variable: 14764
                         └──Type expr: Arrow
                            └──Type expr: Variable: 14764
                            └──Type expr: Constructor: int
                   └──Desc: Variable: f
                └──Abstraction:
                   └──Variables: 14764
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: t
                            └──Type expr: Variable: 14764
                         └──Type expr: Arrow
                            └──Type expr: Constructor: t
                               └──Type expr: Variable: 14764
                            └──Type expr: Arrow
                               └──Type expr: Variable: 14764
                               └──Type expr: Constructor: int
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: t
                               └──Type expr: Variable: 14764
                            └──Desc: Variable: t1
                         └──Expression:
                            └──Type expr: Arrow
                               └──Type expr: Constructor: t
                                  └──Type expr: Variable: 14764
                               └──Type expr: Arrow
                                  └──Type expr: Variable: 14764
                                  └──Type expr: Constructor: int
                            └──Desc: Function
                               └──Pattern:
                                  └──Type expr: Constructor: t
                                     └──Type expr: Variable: 14764
                                  └──Desc: Variable: t2
                               └──Expression:
                                  └──Type expr: Arrow
                                     └──Type expr: Variable: 14764
                                     └──Type expr: Constructor: int
                                  └──Desc: Function
                                     └──Pattern:
                                        └──Type expr: Variable: 14764
                                        └──Desc: Variable: x
                                     └──Expression:
                                        └──Type expr: Constructor: int
                                        └──Desc: Match
                                           └──Expression:
                                              └──Type expr: Tuple
                                                 └──Type expr: Constructor: t
                                                    └──Type expr: Variable: 14764
                                                 └──Type expr: Constructor: t
                                                    └──Type expr: Variable: 14764
                                              └──Desc: Tuple
                                                 └──Expression:
                                                    └──Type expr: Constructor: t
                                                       └──Type expr: Variable: 14764
                                                    └──Desc: Variable
                                                       └──Variable: t1
                                                 └──Expression:
                                                    └──Type expr: Constructor: t
                                                       └──Type expr: Variable: 14764
                                                    └──Desc: Variable
                                                       └──Variable: t2
                                           └──Type expr: Tuple
                                              └──Type expr: Constructor: t
                                                 └──Type expr: Variable: 14764
                                              └──Type expr: Constructor: t
                                                 └──Type expr: Variable: 14764
                                           └──Cases:
                                              └──Case:
                                                 └──Pattern:
                                                    └──Type expr: Tuple
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14764
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14764
                                                    └──Desc: Tuple
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14764
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Ab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14764
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14764
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Ab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14764
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Match
                                                       └──Expression:
                                                          └──Type expr: Variable: 14764
                                                          └──Desc: Variable
                                                             └──Variable: x
                                                       └──Type expr: Variable: 14764
                                                       └──Cases:
                                                          └──Case:
                                                             └──Pattern:
                                                                └──Type expr: Variable: 14764
                                                                └──Desc: Construct
                                                                   └──Constructor description:
                                                                      └──Name: A
                                                                      └──Constructor type:
                                                                         └──Type expr: Variable: 14764
                                                             └──Expression:
                                                                └──Type expr: Constructor: int
                                                                └──Desc: Constant: 1
                                              └──Case:
                                                 └──Pattern:
                                                    └──Type expr: Tuple
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14764
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14764
                                                    └──Desc: Tuple
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14764
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Mab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14764
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14764
                                                          └──Desc: Any
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Match
                                                       └──Expression:
                                                          └──Type expr: Variable: 14764
                                                          └──Desc: Variable
                                                             └──Variable: x
                                                       └──Type expr: Variable: 14764
                                                       └──Cases:
                                                          └──Case:
                                                             └──Pattern:
                                                                └──Type expr: Variable: 14764
                                                                └──Desc: Construct
                                                                   └──Constructor description:
                                                                      └──Name: A
                                                                      └──Constructor type:
                                                                         └──Type expr: Variable: 14764
                                                             └──Expression:
                                                                └──Type expr: Constructor: int
                                                                └──Desc: Constant: 2
                                              └──Case:
                                                 └──Pattern:
                                                    └──Type expr: Tuple
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14764
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14764
                                                    └──Desc: Tuple
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14764
                                                          └──Desc: Any
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14764
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Ab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14764
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Match
                                                       └──Expression:
                                                          └──Type expr: Variable: 14764
                                                          └──Desc: Variable
                                                             └──Variable: x
                                                       └──Type expr: Variable: 14764
                                                       └──Cases:
                                                          └──Case:
                                                             └──Pattern:
                                                                └──Type expr: Variable: 14764
                                                                └──Desc: Construct
                                                                   └──Constructor description:
                                                                      └──Name: B
                                                                      └──Constructor type:
                                                                         └──Type expr: Variable: 14764
                                                             └──Expression:
                                                                └──Type expr: Constructor: int
                                                                └──Desc: Constant: 3
                                              └──Case:
                                                 └──Pattern:
                                                    └──Type expr: Tuple
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14764
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14764
                                                    └──Desc: Tuple
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14764
                                                          └──Desc: Any
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14764
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Mab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14764
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Match
                                                       └──Expression:
                                                          └──Type expr: Variable: 14764
                                                          └──Desc: Variable
                                                             └──Variable: x
                                                       └──Type expr: Variable: 14764
                                                       └──Cases:
                                                          └──Case:
                                                             └──Pattern:
                                                                └──Type expr: Variable: 14764
                                                                └──Desc: Construct
                                                                   └──Constructor description:
                                                                      └──Name: B
                                                                      └──Constructor type:
                                                                         └──Type expr: Variable: 14764
                                                             └──Expression:
                                                                └──Type expr: Constructor: int
                                                                └──Desc: Constant: 4 |}]

let%expect_test "" = 
  let str = 
    {|
      type 'a ab = A | B;;

      type 'a mab = 'a ab;;  
      type 'a t = 
        | Ab constraint 'a = unit ab
        | Mab constraint 'a = unit mab
      ;;   

      let ab = Ab;;
      let a = A;;
      let b = B;;

      let (type 'a) f = 
        fun (t1 : 'a t) (t2 : 'a t) (x : 'a) ->
          match (t1, t2) with
          ( (Ab, Ab) -> match x with ( A -> 1 )
          | (_, Ab) -> match x with ( A -> 2 )
          | (_, Ab) -> match x with ( B -> 3 )
          | (_, Mab) -> 4
          )
      ;;
    |}
  in
  print_infer_result str;
  [%expect {|
    Structure:
    └──Structure:
       └──Structure item: Type
          └──Type declaration:
             └──Type name: ab
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: A
                   └──Constructor alphas: 14859
                   └──Constructor type:
                      └──Type expr: Constructor: ab
                         └──Type expr: Variable: 14859
                └──Constructor declaration:
                   └──Constructor name: B
                   └──Constructor alphas: 14859
                   └──Constructor type:
                      └──Type expr: Constructor: ab
                         └──Type expr: Variable: 14859
       └──Structure item: Type
          └──Type declaration:
             └──Type name: mab
             └──Type declaration kind: Alias
                └──Alias
                   └──Alias name: mab
                   └──Alias alphas: 14862
                   └──Type expr: Constructor: ab
                      └──Type expr: Variable: 14862
       └──Structure item: Type
          └──Type declaration:
             └──Type name: t
             └──Type declaration kind: Variant
                └──Constructor declaration:
                   └──Constructor name: Ab
                   └──Constructor alphas: 14864
                   └──Constructor type:
                      └──Type expr: Constructor: t
                         └──Type expr: Variable: 14864
                   └──Constraint:
                      └──Type expr: Variable: 14864
                      └──Type expr: Constructor: ab
                         └──Type expr: Constructor: unit
                └──Constructor declaration:
                   └──Constructor name: Mab
                   └──Constructor alphas: 14864
                   └──Constructor type:
                      └──Type expr: Constructor: t
                         └──Type expr: Variable: 14864
                   └──Constraint:
                      └──Type expr: Variable: 14864
                      └──Type expr: Constructor: mab
                         └──Type expr: Constructor: unit
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Constructor: t
                      └──Type expr: Constructor: ab
                         └──Type expr: Constructor: unit
                   └──Desc: Variable: ab
                └──Abstraction:
                   └──Variables:
                   └──Expression:
                      └──Type expr: Constructor: t
                         └──Type expr: Constructor: ab
                            └──Type expr: Constructor: unit
                      └──Desc: Construct
                         └──Constructor description:
                            └──Name: Ab
                            └──Constructor type:
                               └──Type expr: Constructor: t
                                  └──Type expr: Constructor: ab
                                     └──Type expr: Constructor: unit
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Constructor: ab
                      └──Type expr: Variable: 14880
                   └──Desc: Variable: a
                └──Abstraction:
                   └──Variables: 14880
                   └──Expression:
                      └──Type expr: Constructor: ab
                         └──Type expr: Variable: 14880
                      └──Desc: Construct
                         └──Constructor description:
                            └──Name: A
                            └──Constructor type:
                               └──Type expr: Constructor: ab
                                  └──Type expr: Variable: 14880
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Constructor: ab
                      └──Type expr: Variable: 14884
                   └──Desc: Variable: b
                └──Abstraction:
                   └──Variables: 14884
                   └──Expression:
                      └──Type expr: Constructor: ab
                         └──Type expr: Variable: 14884
                      └──Desc: Construct
                         └──Constructor description:
                            └──Name: B
                            └──Constructor type:
                               └──Type expr: Constructor: ab
                                  └──Type expr: Variable: 14884
       └──Structure item: Let
          └──Value bindings:
             └──Value binding:
                └──Pattern:
                   └──Type expr: Arrow
                      └──Type expr: Constructor: t
                         └──Type expr: Variable: 14896
                      └──Type expr: Arrow
                         └──Type expr: Constructor: t
                            └──Type expr: Variable: 14896
                         └──Type expr: Arrow
                            └──Type expr: Variable: 14896
                            └──Type expr: Constructor: int
                   └──Desc: Variable: f
                └──Abstraction:
                   └──Variables: 14896
                   └──Expression:
                      └──Type expr: Arrow
                         └──Type expr: Constructor: t
                            └──Type expr: Variable: 14896
                         └──Type expr: Arrow
                            └──Type expr: Constructor: t
                               └──Type expr: Variable: 14896
                            └──Type expr: Arrow
                               └──Type expr: Variable: 14896
                               └──Type expr: Constructor: int
                      └──Desc: Function
                         └──Pattern:
                            └──Type expr: Constructor: t
                               └──Type expr: Variable: 14896
                            └──Desc: Variable: t1
                         └──Expression:
                            └──Type expr: Arrow
                               └──Type expr: Constructor: t
                                  └──Type expr: Variable: 14896
                               └──Type expr: Arrow
                                  └──Type expr: Variable: 14896
                                  └──Type expr: Constructor: int
                            └──Desc: Function
                               └──Pattern:
                                  └──Type expr: Constructor: t
                                     └──Type expr: Variable: 14896
                                  └──Desc: Variable: t2
                               └──Expression:
                                  └──Type expr: Arrow
                                     └──Type expr: Variable: 14896
                                     └──Type expr: Constructor: int
                                  └──Desc: Function
                                     └──Pattern:
                                        └──Type expr: Variable: 14896
                                        └──Desc: Variable: x
                                     └──Expression:
                                        └──Type expr: Constructor: int
                                        └──Desc: Match
                                           └──Expression:
                                              └──Type expr: Tuple
                                                 └──Type expr: Constructor: t
                                                    └──Type expr: Variable: 14896
                                                 └──Type expr: Constructor: t
                                                    └──Type expr: Variable: 14896
                                              └──Desc: Tuple
                                                 └──Expression:
                                                    └──Type expr: Constructor: t
                                                       └──Type expr: Variable: 14896
                                                    └──Desc: Variable
                                                       └──Variable: t1
                                                 └──Expression:
                                                    └──Type expr: Constructor: t
                                                       └──Type expr: Variable: 14896
                                                    └──Desc: Variable
                                                       └──Variable: t2
                                           └──Type expr: Tuple
                                              └──Type expr: Constructor: t
                                                 └──Type expr: Variable: 14896
                                              └──Type expr: Constructor: t
                                                 └──Type expr: Variable: 14896
                                           └──Cases:
                                              └──Case:
                                                 └──Pattern:
                                                    └──Type expr: Tuple
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14896
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14896
                                                    └──Desc: Tuple
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14896
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Ab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14896
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14896
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Ab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14896
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Match
                                                       └──Expression:
                                                          └──Type expr: Variable: 14896
                                                          └──Desc: Variable
                                                             └──Variable: x
                                                       └──Type expr: Variable: 14896
                                                       └──Cases:
                                                          └──Case:
                                                             └──Pattern:
                                                                └──Type expr: Variable: 14896
                                                                └──Desc: Construct
                                                                   └──Constructor description:
                                                                      └──Name: A
                                                                      └──Constructor type:
                                                                         └──Type expr: Variable: 14896
                                                             └──Expression:
                                                                └──Type expr: Constructor: int
                                                                └──Desc: Constant: 1
                                              └──Case:
                                                 └──Pattern:
                                                    └──Type expr: Tuple
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14896
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14896
                                                    └──Desc: Tuple
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14896
                                                          └──Desc: Any
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14896
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Ab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14896
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Match
                                                       └──Expression:
                                                          └──Type expr: Variable: 14896
                                                          └──Desc: Variable
                                                             └──Variable: x
                                                       └──Type expr: Variable: 14896
                                                       └──Cases:
                                                          └──Case:
                                                             └──Pattern:
                                                                └──Type expr: Variable: 14896
                                                                └──Desc: Construct
                                                                   └──Constructor description:
                                                                      └──Name: A
                                                                      └──Constructor type:
                                                                         └──Type expr: Variable: 14896
                                                             └──Expression:
                                                                └──Type expr: Constructor: int
                                                                └──Desc: Constant: 2
                                              └──Case:
                                                 └──Pattern:
                                                    └──Type expr: Tuple
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14896
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14896
                                                    └──Desc: Tuple
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14896
                                                          └──Desc: Any
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14896
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Ab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14896
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Match
                                                       └──Expression:
                                                          └──Type expr: Variable: 14896
                                                          └──Desc: Variable
                                                             └──Variable: x
                                                       └──Type expr: Variable: 14896
                                                       └──Cases:
                                                          └──Case:
                                                             └──Pattern:
                                                                └──Type expr: Variable: 14896
                                                                └──Desc: Construct
                                                                   └──Constructor description:
                                                                      └──Name: B
                                                                      └──Constructor type:
                                                                         └──Type expr: Variable: 14896
                                                             └──Expression:
                                                                └──Type expr: Constructor: int
                                                                └──Desc: Constant: 3
                                              └──Case:
                                                 └──Pattern:
                                                    └──Type expr: Tuple
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14896
                                                       └──Type expr: Constructor: t
                                                          └──Type expr: Variable: 14896
                                                    └──Desc: Tuple
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14896
                                                          └──Desc: Any
                                                       └──Pattern:
                                                          └──Type expr: Constructor: t
                                                             └──Type expr: Variable: 14896
                                                          └──Desc: Construct
                                                             └──Constructor description:
                                                                └──Name: Mab
                                                                └──Constructor type:
                                                                   └──Type expr: Constructor: t
                                                                      └──Type expr: Variable: 14896
                                                 └──Expression:
                                                    └──Type expr: Constructor: int
                                                    └──Desc: Constant: 4 |}]