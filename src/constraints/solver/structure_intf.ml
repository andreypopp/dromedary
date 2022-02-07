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

(* This module implements signatured used for unification structures. *)

open! Import

module type Identifiable = sig
  type 'a t

  val id : 'a t -> int
end

module type Metadata = sig
  type 'a t [@@deriving sexp_of]

  val empty : unit -> 'a t
  val merge : 'a t -> 'a t -> 'a t
end

module type S = sig
  (** A structure defines the "structure" of the unification type.

      We define a structure as a pair [(desc, metadata)], consistings of a descriptor
      ['a desc] and some metadata ['a metadata]. 
      
      We explicitly split these for composability reasons. 
  *)
  module Metadata : Metadata

  type 'a t [@@deriving sexp_of]

  val map : 'a t -> f:('a -> 'b) -> 'b t
  val iter : 'a t -> f:('a -> unit) -> unit
  val fold : 'a t -> f:('a -> 'b -> 'b) -> init:'b -> 'b

  (** Descriptors must exhibit [merge], which is the ability
      to compute a logically consistent descriptor from 2 descriptor. 

      If the 2 descriptors are not consistent, then we raise [Cannot_merge].
      
      Consistency is determined via the ability to emit first-order equalities,
      provided by [equate].

      In some cases, logical consistency of 2 descriptor requires a context. 
      (e.g. Abbreviations, and Ambivalence), thus [merge] requires a
      context [ctx]. 
      
      In some cases, consistency may also a notion of "expansiveness", the ability
      to create new terms during [merge]. This is defined in the context ['a expansive]
  *)

  type 'a expansive
  type ctx

  exception Cannot_merge

  val merge
    :  expansive:'a expansive
    -> ctx:ctx
    -> equate:('a -> 'a -> unit)
    -> 'a t * 'a Metadata.t
    -> 'a t * 'a Metadata.t
    -> 'a t
end

module type Intf = sig
  module type S = S

  module Rigid_var : sig
    type t = private int [@@deriving sexp_of, compare]

    val make : unit -> t
    val hash : t -> int
  end

  module Of_former (Former : Type_former.S) : sig
    include
      S
        with type 'a Metadata.t = unit
         and type 'a t = 'a Former.t
         and type 'a expansive = unit
         and type ctx = unit
  end

  module First_order (S : S) : sig
    type 'a t =
      | Var
      | Structure of 'a S.t

    include
      S
        with type 'a Metadata.t = 'a S.Metadata.t
         and type 'a t := 'a t
         and type ctx = S.ctx
         and type 'a expansive = 'a S.expansive
  end

  module Scoped_abbreviations
      (S : S)
      (Id : Identifiable with type 'a t := 'a S.t) : sig
    module Abbrev : sig
      module Type : sig
        type t [@@deriving sexp_of, compare]

        type structure =
          | Var
          | Structure of t S.t

        val structure : t -> structure
        
        val make : structure -> t
      end

      module Scope : sig
        type t = int [@@deriving sexp_of]

        val outermost_scope : t
      end

      type t = 
        { structure : Type.t S.t
        ; type_ : Type.t
        ; scope : Scope.t
        }
      [@@deriving sexp_of]

      module Ctx : sig
        type abbrev := t
        type t

        val empty : t
        val find : t -> _ S.t -> abbrev option
        val add : t -> abbrev:Type.t S.t * Type.t -> scope:Scope.t -> t
      end
    end

    module Metadata : sig
      type 'a t [@@deriving sexp_of]

      (** [scope t] *)
      val scope : 'a t -> Abbrev.Scope.t

      (** [update_scope t scope] updates the scope of [t] according to [scope]. *)
      val update_scope : 'a t -> Abbrev.Scope.t -> unit

      (** [super_ t] returns the parent metadata. *)
      val super_ : 'a t -> 'a S.Metadata.t

      include Metadata with type 'a t := 'a t
    end

    type 'a t

    val make : 'a S.t -> 'a t
    val repr : 'a t -> 'a S.t

    type 'a expansive =
      { make_structure : 'a S.t -> 'a
      ; make_var : unit -> 'a
      ; super_ : 'a S.expansive
      }

    include
      S
        with module Metadata := Metadata
         and type 'a t := 'a t
         and type ctx = Abbrev.Ctx.t * S.ctx
         and type 'a expansive := 'a expansive
  end

  module Rigid_structure (S : S) : sig
    type 'a t =
      | Rigid_var of Rigid_var.t
      | Structure of 'a S.t

    include
      S
        with type 'a Metadata.t = 'a S.Metadata.t
         and type 'a t := 'a t
         and type ctx = S.ctx
         and type 'a expansive = 'a S.expansive
  end

  module Rigid_identifiable (S : S) (Id : Identifiable with type 'a t = 'a S.t) : sig
    module Rigid_structure := Rigid_structure(S)
    include Identifiable with type 'a t = 'a Rigid_structure.t
  end
end