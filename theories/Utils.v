Set Universe Polymorphism.

From Coq Require Import JMeq Program.Equality EqdepFacts.
Require Import RelationClasses.
From ExtLib.Data Require Import Nat Fin.

From Equations Require Import Equations.
Set Equations Transparent.

Derive Signature for fin.

(******************)
(* misc notations *)

#[global] Notation endo T := (T -> T).
  
#[global] Notation "f ∘ g" := (Basics.compose f g) (at level 40, left associativity) : function_scope.  
Definition compose {A : Type} {B : A -> Type} {C : forall a, B a -> Type}
           (g : forall a (b : B a), C _ b)
           (f : forall a, B a)
           : forall a, C _ (f a) := fun a => g _ (f a).
#[global] Notation "f ∘' g" := (compose f g) (at level 60) : function_scope. 

Notation "a ,& b" := (existT _ a b) (at level 30).
(*Notation "'ex' a" := (existT _ _ a) (at level 30).*)

Definition uncurry2 {A B : Type} {C : A -> B -> Type}
                    (f : forall a b, C a b) (i : A * B) :=
  f (fst i) (snd i).
Definition curry2 {A B : Type} {C : A -> B -> Type}
                  (f : forall i, C (fst i) (snd i)) a b :=
  f (a , b).

Definition uncurry2' {A : Type} {B : A -> Type} {C : forall a, B a -> Type}
                    (f : forall a b, C a b) (i : sigT B) :=
  f (projT1 i) (projT2 i).

(*
Definition curry2' {A : Type} {B : A -> Type} {C : forall a, B a -> Type}
                  (f : forall i, C (projT1 i) (projT2 i)) a b :=
  f (a ,& b).
*)
Notation curry2' := (fun f a b => f (a ,& b)).


(***************)
(* Finite sets *)

Variant T0 := .
Variant T1 := t1_0.
Variant T2 := t2_0 | t2_1.
Variant T3 := t3_0 | t3_1 | t3_2.

Definition ex_falso {A : Type} (bot : T0) : A := match bot with end.

Definition voidᵢ {I : Type} : I -> Type := fun _ => T0.
Notation "∅ᵢ" := (voidᵢ).


(********************************)
(* Couple lemma on list/vec/fin *)

(*

Equations s_case {A B C : Type} (x : A + B) (f : A -> C) (g : B -> C) : C :=
  s_case (inl a) f g := f a ;
  s_case (inr b) f g := g b .

Equations f_split {a b} (i : fin (a + b)) : (fin a + fin b) :=
  @f_split O     _ i := inr i ;
  @f_split (S n) _ F0 := inl F0 ;
  @f_split (S n) _ (FS i) with f_split i := {
     | inl i := inl (FS i) ;
     | inr i := inr i } .

Equations f_split_list {X : Type} {xs ys : list X} (i : fin (length (xs ++ ys)))
           : fin (length xs) + fin (length ys) :=
  @f_split_list _ nil        _ i := inr i ;
  @f_split_list _ (cons _ _) _ F0     := inl F0 ;
  @f_split_list _ (cons _ _) _ (FS i) with f_split_list i := {
     | inl i := inl (FS i) ;
     | inr i := inr i } .
*)

Equations l_get {X} (xs : list X) : fin (length xs) -> X :=
  l_get (cons x xs) F0     := x ;
  l_get (cons x xs) (FS i) := l_get xs i.

Notation "xs .[ i ]" := (l_get xs i) (at level 10).

(*
Equations f_split_get {X} {xs ys : list X} i : (xs ++ ys) .[i] = s_case (f_split_list i) (l_get xs) (l_get ys) :=
  @f_split_get _ nil        _ i := eq_refl ;
  @f_split_get _ (cons _ _) _ F0     := eq_refl ;
  @f_split_get _ (cons _ _) _ (FS i) with f_split_list i := {
                                                             | inl i := _ ;
                                                          | inr i := _  } .
Obligation 2.
*)


Equations l_acc {X} (n : nat) (f : fin n -> X) : list X :=
  l_acc O     f := nil ;
  l_acc (S n) f := cons (f F0) (l_acc n (f ∘ FS)).

Equations len_acc {X} n (f : fin n -> X) : length (l_acc n f) = n :=
  len_acc O     f := eq_refl ;
  len_acc (S n) f := f_equal S (len_acc n (f ∘ FS)).

(*
Record list' (X : Type) : Type := List' { len : nat ; val : fin len -> X }.
Arguments len {X}.
Arguments val {X}.

Definition l_any {X : Type} (T : X -> Type) (xs : list' X) : Type :=
  { i : fin (len xs) & T (val xs i) }.

Definition l_all {X : Type} (T : X -> Type) (xs : list' X) : Type :=
  forall i : fin (len xs), T (val xs i).

Definition l_curry {X : Type} {T : X -> Type} (U : forall x, T x -> Type)
           {xs} (h : forall e : l_any T xs, U _ (projT2 e))
           : l_all (fun x -> forall t : T x, ) xs


*)


Equations dvec {X} (ty : X -> Type) (xs : list X) : Type :=
  dvec ty nil := T1 ;
  dvec ty (cons x xs) := ty x * dvec ty xs.
Transparent dvec.

Equations d_collect {X} {ty : X -> Type} (xs : list X) (f : forall i, ty (xs .[i])) : dvec ty xs :=
  d_collect nil f := t1_0 ;
  d_collect (cons x xs) f := (f F0 , d_collect xs (fun i => f (FS i))).
Arguments d_collect {X ty xs}.

Equations d_get {X ty} (c : list X) (d : dvec ty c) (i : fin (length c)) : ty (l_get c i) :=
  d_get (cons t ts) r F0     := fst r ;
  d_get (cons t ts) r (FS i) := d_get ts (snd r) i.


(*
Equations d_collect_lem {X} {ty : X -> Type} (xs : list X) (f : forall i, ty (xs .[i]))
          : forall i, d_get 
*)

Equations d_concat {X ty} (a b : list X) (d : dvec ty a) (h : forall i : fin (length b), ty (b .[i])) : dvec ty (b ++ a) :=
  d_concat _ nil        d h := d ;
  d_concat _ (cons _ _) d h := (h F0 , d_concat _ _ d (fun i => h (FS i))).

Equations d_concat_lem {X ty} (P : forall x, ty x -> ty x -> Prop)
          (a b : list X) (d0 d1 : dvec ty a)
          (f0 f1 : forall i : fin (length b), ty (b .[i]))
          (Hd : forall i, P (a .[i]) (d_get _ d0 i) (d_get _ d1 i))
          (Hf : forall i, P (b .[i]) (f0 i) (f1 i))
          : forall i, P ((b ++ a) .[i]) (d_get _ (d_concat _ _ d0 f0) i)
                   (d_get _ (d_concat _ _ d1 f1) i) :=
  d_concat_lem P _ nil        d0 d1 f0 f1 Hd Hf i := Hd i ;
  d_concat_lem P _ (cons _ _) d0 d1 f0 f1 Hd Hf (F0)   := Hf F0 ;
  d_concat_lem P _ (cons _ _) d0 d1 f0 f1 Hd Hf (FS i) :=
    d_concat_lem P _ _ _ _  _ _ _ (fun i => Hf (FS i)) i.

Equations fin_inj' {X} {a b : list X} : fin (length a) -> fin (length (a ++ b)) :=
  @fin_inj' _ (cons _ _) _ (F0)   := F0 ;
  @fin_inj' _ (cons _ _) _ (FS i) := FS (fin_inj' i) .


Equations fin_inj_get {X} {a b : list X} (i : fin (length a)) : a .[i] = (a ++ b) .[fin_inj' i] :=
  @fin_inj_get _ (cons _ _) _ (F0) := _ ;
  @fin_inj_get _ (cons _ _) _ (FS i) := fin_inj_get i .

Equations fin_inj_dget {X} {a b : list X} {ty} (d : dvec ty b)
           (h : forall i : fin (length a), ty (a .[i]))
           (i : fin (length a))
           : d_get _ (d_concat b a d h) (fin_inj' i) = eq_rect _ ty (h i) _ (fin_inj_get i) :=
  @fin_inj_dget _ (cons _ _) _ _ _ _ (F0) := _ ;
  @fin_inj_dget _ (cons _ _) _ _ _ _ (FS i) := fin_inj_dget _ _ i .

Definition pi_lem_eq
    {A : Type} {x y : A} (H0 : y = x)
    {B : A -> Type} {C : forall a, B a -> Type}
    (f : forall b : B x, C x b)
    (g : forall b : B y, C y b)

    (H1 : f = eq_rect _ (fun a => forall b : B a, C a b) g _ H0)

    (b : B y) : eq_dep (sigT B) (fun a => C (projT1 a) (projT2 a)) (_ ,& _) (f (eq_rect _ B b _ H0)) (_ ,& _) (g b).
  dependent induction H1; auto.
Defined.
                 



Declare Scope indexed_scope.
Open Scope indexed_scope.
Delimit Scope indexed_scope with indexed.

Variant prod1 (D E : Type -> Type) : Type -> Type :=
| pair1 : forall {X Y}, D X -> E Y -> prod1 D E (X * Y).

#[global] Notation "D *' E" := (prod1 D E) (at level 50).

(* (covariant) presheaves *)
Definition psh (I : Type) : Type := I -> Type.


Definition relᵢ {I : Type} (A B : psh I) := forall i, A i -> B i -> Prop.
Notation Reflexiveᵢ R := (forall i, Reflexive (R i)).
Notation Symmetricᵢ R := (forall i, Symmetric (R i)).
Notation Transitiveᵢ R := (forall i, Transitive (R i)).
Definition subrelᵢ {I : Type} {A B : psh I} (R1 R2 : relᵢ A B) : Prop :=
  forall i a b, R1 i a b -> R2 i a b.

Definition flipᵢ {I : Type} {A B : psh I} (R : relᵢ A B) : relᵢ B A :=
  fun i x y => R i y x.



Definition eqᵢ {I : Type} {X : psh I} : relᵢ X X := fun i x y => x = y.
Arguments eqᵢ _ _ _ /.

(* pointwise arrows *)
Definition arrᵢ {I} (X Y : psh I) : Type := forall {i}, X i -> Y i.
#[global] Infix "⇒ᵢ" := (arrᵢ) (at level 20) : indexed_scope.

(* pointwise coproduct *)
Definition sumᵢ {I} (X Y : psh I) : psh I := fun i => (X i + Y i)%type.
Infix "+ᵢ" := (sumᵢ) (at level 20) : indexed_scope.

(* pointwise arrows between F G : endo (psh I) *)
Notation "F ⇒f G" := (forall X : psh _, F X ⇒ᵢ G X) (at level 30).


Inductive fiber {A B} (f : A -> B) : B -> Type := Fib a : fiber f (f a).
Arguments Fib {A B f}.
Derive NoConfusion for fiber.

(* These two functions actually form an isomorphism (extensionally)
      (fiber f ⇒ᵢ X) ≅ (∀ a → X (f a))
 *)
Definition fiber_ext {A B} {f : A -> B} {b : B} : fiber f b -> A :=
  fun '(Fib a) => a.
Definition fiber_coh {A B} {f : A -> B} {b : B} :
    forall p : fiber f b, f (fiber_ext p) = b :=
  fun '(Fib _) => eq_refl.
Definition fiber_mk {A B} {f : A -> B} a : forall b (p : f a = b), fiber f b :=
  eq_rect (f a) (fiber f) (Fib a).
 
Definition fiber_into {A B} {f : A -> B} X (h : forall a, X (f a)) : fiber f ⇒ᵢ X :=
  fun _ '(Fib a) => h a.
Definition fiber_from {A B} {f : A -> B} X (h : fiber f ⇒ᵢ X) a : X (f a) :=
  h _ (Fib a).

Notation "X @ i" := (fiber (fun (_ : X) => i)) (at level 20) : indexed_scope.
Definition pin {I X} (i : I) : X -> (X @ i) i := Fib.
Definition pin_from {I X Y} {i : I} : ((X @ i) ⇒ᵢ Y) -> (X -> Y i) := fiber_from _.
Definition pin_into {I X Y} {i : I} : (X -> Y i) -> (X @ i ⇒ᵢ Y) := fiber_into _.
