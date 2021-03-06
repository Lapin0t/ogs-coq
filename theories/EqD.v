From Coq Require Import Program Morphisms.
From OGS Require Import Utils EventD ITreeD.
From Paco Require Import paco.
Import EqNotations.

Tactic Notation "hinduction" hyp(IND) "before" hyp(H)
  := move IND before H; revert_until IND; induction IND.


Section eqit.
  Context {I : Type} {E : event I I} {R1 R2 : I -> Type} (RR : relᵢ R1 R2).

  Inductive eqitF (b1 b2: bool) (vclo : endo (relᵢ (itree E R1) (itree E R2)))
                             (sim : relᵢ (itree E R1) (itree E R2)) i
    : itree' E R1 i -> itree' E R2 i -> Prop :=
    | EqRet r1 r2
       (REL: RR i r1 r2)
       : eqitF b1 b2 vclo sim i (RetF r1) (RetF r2)
    | EqTau m1 m2
        (REL: sim i m1 m2):
        eqitF b1 b2 vclo sim i (TauF m1) (TauF m2)
    | EqVis (e : E.(qry) i) k1 k2
        (REL: forall v, vclo sim _ (k1 v) (k2 v) : Prop):
        eqitF b1 b2 vclo sim i (VisF e k1) (VisF e k2)
    | EqTauL t1 ot2
        (CHECK: is_true b1)
        (REL: eqitF b1 b2 vclo sim i (observe t1) ot2):
        eqitF b1 b2 vclo sim i (TauF t1) ot2
    | EqTauR ot1 t2
        (CHECK: is_true b2)
        (REL: eqitF b1 b2 vclo sim i ot1 (observe t2)):
        eqitF b1 b2 vclo sim i ot1 (TauF t2).

  Hint Constructors eqitF: core.

  Definition eqit_ b1 b2 vclo sim : relᵢ (itree E R1) (itree E R2) :=
    fun i t1 t2 => eqitF b1 b2 vclo sim i (observe t1) (observe t2).
  Hint Unfold eqit_: core.

  Definition eqit b1 b2 : relᵢ (itree E R1) (itree E R2) :=
    paco3 (eqit_ b1 b2 id) bot3.

  Lemma eqitF_mono b1 b2 vclo vclo' sim sim' i x0 x1 
        (IN: eqitF b1 b2 vclo sim i x0 x1)
        (MON: monotone3 vclo)
        (LEc: vclo <4= vclo')
        (LE: sim <3= sim'):
    eqitF b1 b2 vclo' sim' i x0 x1. 
    induction IN; eauto.
  Qed.

  Lemma eqit__mono b1 b2 vclo (MON: monotone3 vclo) : monotone3 (eqit_ b1 b2 vclo).
    do 2 red. intros; eapply eqitF_mono; eauto.
  Qed.

  Lemma eqit_idclo_mono : monotone3 (@id (relᵢ (itree E R1) (itree E R2))).
    unfold id. eauto. Qed.

  Hint Resolve eqit__mono : paco.
  Hint Resolve eqit_idclo_mono : paco.

  Definition eutt := eqit true true.
  Definition eq_itree := eqit false false.
  Definition euttge := eqit true false.
End eqit.

Arguments EqRet {I E R1 R2 RR b1 b2 vclo sim i}.
Arguments EqTau {I E R1 R2 RR b1 b2 vclo sim i}.
Arguments EqVis {I E R1 R2 RR b1 b2 vclo sim i}.
Arguments EqTauL {I E R1 R2 RR b1 b2 vclo sim i}.
Arguments EqTauR {I E R1 R2 RR b1 b2 vclo sim i}.

#[global] Hint Constructors eqitF: core.
#[global] Hint Unfold eqit_: core.
#[global] Hint Resolve eqit__mono : paco.
#[global] Hint Resolve eqit_idclo_mono : paco.
#[global] Hint Unfold eqit: core.
(*#[global] Hint Unfold eq_itree: core.*)
#[global] Hint Unfold eutt: core.
(*#[global] Hint Unfold euttge: core.*)
#[global] Hint Unfold id: core.
#[global] Infix "≈" := (eutt eqᵢ _) (at level 70) : type_scope.


Section eqit_trans.
  Context {I} {E : event I I} {R1 R2 : psh I} (RR : relᵢ R1 R2).
  Inductive eqit_trans_clo b1 b2
               (r : relᵢ (itree E R1) (itree E R2)) i
           : itree E R1 i -> itree E R2 i -> Prop :=
  | eqit_trans_clo_intro t1 t2 t1' t2' RR1 RR2
      (EQVl: eqit RR1 b1 false i t1 t1')
      (EQVr: eqit RR2 b2 false i t2 t2')
      (REL: r i t1' t2')
      (LERR1: forall i x x' y, RR1 i x x' -> RR i x' y -> RR i x y)
      (LERR2: forall i x y y', RR2 i y y' -> RR i x y' -> RR i x y)
  : eqit_trans_clo b1 b2 r i t1 t2
  .
  Hint Constructors eqit_trans_clo: core.

  Definition eqitC := eqit_trans_clo.
  Hint Unfold eqitC: core.

Lemma eqitC_mon b1 b2 r1 r2 i t1 t2
      (IN: eqitC b1 b2 r1 i t1 t2)
      (LE: r1 <3= r2):
  eqitC b1 b2 r2 i t1 t2.
  destruct IN; econstructor; eauto.
Qed.
Hint Resolve eqitC_mon : paco.

Lemma eq_inv_VisF_weak {R i} (e1 e2 : E.(qry) i)
      (k1 : forall r, itree E R _) (k2 : forall r, itree E R _)
  : VisF (R := R) e1 k1 = VisF (R := R) e2 k2 ->
    { p : e1 = e2 & rew [ fun _ => forall r, _ ] p in k1 = k2 }.
  intros.
  injection H as _ H1.
  inversion_sigma.
  eauto.
Qed.


Ltac unfold_eqit :=
  (try match goal with [|- eqit_ _ _ _ _ _ _ _ _ ] => red end);
  (repeat match goal with [H: eqit_ _ _ _ _ _ _ _ _ |- _ ] => red in H end).

Ltac inv H := inversion H; clear H; subst.

Ltac inv_Vis :=
  discriminate +
  match goal with
  | [ E : VisF _ _ = VisF _ _ |- _ ] =>
     apply eq_inv_VisF_weak in E; destruct E as [ <- <- ]
  end.


Lemma eqitC_wcompat b1 b2 vclo
      (MON: monotone3 vclo)
      (CMP: compose (eqitC b1 b2) vclo <4= compose vclo (eqitC b1 b2)):
  wcompatible3 (@eqit_ I E R1 R2 RR b1 b2 vclo) (eqitC b1 b2).
  econstructor. pmonauto.
  intros. destruct PR.
  punfold EQVl. punfold EQVr. unfold_eqit.
  hinduction REL before r; intros; clear t1' t2'.
  + remember (RetF r1) as x.
    hinduction EQVl before r; intros; subst; try inv Heqx; eauto.
    remember (RetF r3) as y.
    hinduction EQVr before r; intros; subst; try inv Heqy; eauto.
  + remember (TauF m1) as x.
    hinduction EQVl before r; intros; subst; try inv Heqx; try inv CHECK; eauto.
    remember (TauF m3) as y.
    hinduction EQVr before r; intros; subst; try inv Heqy; try inv CHECK; eauto.
    pclearbot. econstructor. gclo. econstructor; eauto with paco.
  + remember (VisF e k1) as x.
    hinduction EQVl before r; intros; try discriminate Heqx; eauto; inv_Vis.
    remember (VisF e k3) as y.
    hinduction EQVr before r; intros; try discriminate Heqy; eauto; inv_Vis.
    econstructor. intros. pclearbot.
    eapply MON.
    * apply CMP. econstructor; eauto.
    * intros. apply gpaco3_clo, PR.
  + remember (TauF t1) as x.
    hinduction EQVl before r; intros; subst; try inv Heqx; try inv CHECK; eauto.
    pclearbot. punfold REL.
  + remember (TauF t2) as y.
    hinduction EQVr before r; intros; subst; try inv Heqy; try inv CHECK; eauto.
    pclearbot. punfold REL.
Qed.

Hint Resolve eqitC_wcompat : paco.

Lemma eqit_idclo_compat b1 b2: compose (eqitC b1 b2) id <4= compose id (eqitC b1 b2).
  intros. apply PR.
Qed.
Hint Resolve eqit_idclo_compat : paco.


Lemma eqitC_dist b1 b2:
  forall r1 r2, eqitC b1 b2 (r1 \3/ r2) <3= (eqitC b1 b2 r1 \3/ eqitC b1 b2 r2).
  intros. destruct PR. destruct REL; eauto.
Qed.

Hint Resolve eqitC_dist : paco.

Lemma eqit_clo_trans b1 b2 vclo
      (MON: monotone3 vclo)
      (CMP: compose (eqitC b1 b2) vclo <4= compose vclo (eqitC b1 b2)):
  eqitC b1 b2 <4= gupaco3 (eqit_ RR b1 b2 vclo) (eqitC b1 b2).
  intros. destruct PR. gclo. econstructor; eauto with paco.
Qed.


End eqit_trans.
#[global] Hint Unfold eqitC: core.
#[global] Hint Resolve eqitC_mon : paco.
#[global] Hint Resolve eqitC_wcompat : paco.
#[global] Hint Resolve eqit_idclo_compat : paco.
#[global] Hint Resolve eqitC_dist : paco.
Arguments eqit_clo_trans : clear implicits.
#[global] Hint Constructors eqit_trans_clo: core.

Section eqit_gen.
Context {I} {E : event I I} {R: I -> Type} (RR : relᵢ R R).

Global Instance Reflexive_eqitF b1 b2 (sim : relᵢ (itree E R) (itree E R))
  : Reflexiveᵢ RR
    -> Reflexiveᵢ sim
    -> Reflexiveᵢ (eqitF RR b1 b2 id sim).
intros.
red. destruct x; constructor; eauto.
exact (H i r).
exact (H0 i t).
intro v. exact (H0 _ (k v)).
Qed.

Global Instance Symmetric_eqitF b (sim : relᵢ (itree E R) (itree E R))
  : Symmetricᵢ RR
    -> Symmetricᵢ sim
    -> Symmetricᵢ (eqitF RR b b id sim).
  red. induction 3; constructor; subst; eauto.
  exact (H i _ _ REL).
  exact (H0 i _ _ REL).
  intro v. exact (H0 _ _ _ (REL v)).
Qed.

Global Instance Reflexive_eqit_ b1 b2 (sim : relᵢ (itree E R) (itree E R))
  : Reflexiveᵢ RR
    -> Reflexiveᵢ sim
    -> Reflexiveᵢ (eqit_ RR b1 b2 id sim).
repeat red; intros; reflexivity. Qed.

Global Instance Symmetric_eqit_ b (sim : relᵢ (itree E R) (itree E R))
  : Symmetricᵢ RR
    -> Symmetricᵢ sim
    -> Symmetricᵢ (eqit_ RR b b id sim).
repeat red; symmetry; auto. Qed.

Global Instance Reflexive_eqit_gen b1 b2 (r rg : relᵢ (itree E R) (itree E R))
  : Reflexiveᵢ RR
    -> Reflexiveᵢ (gpaco3 (eqit_ RR b1 b2 id) (eqitC RR b1 b2) r rg).
gcofix CIH. gstep; intros.
repeat red. destruct (observe x); eauto with paco.
econstructor; apply H0.
Qed.

Global Instance Reflexive_eqit b1 b2 : Reflexiveᵢ RR
                                       -> Reflexiveᵢ (@eqit I E _ _ RR b1 b2).
red; intros. ginit. apply Reflexive_eqit_gen; eauto.
Qed.

Lemma eqit_flip b1 b2 : forall i u v,
    eqit (flipᵢ RR) b2 b1 i v u -> @eqit I E _ _ RR b1 b2 i u v.
Proof.
  pcofix self; pstep. intros i u v euv. punfold euv.
  red in euv |- *. induction euv; pclearbot; eauto 7 with paco.
Qed.

Lemma eqit_mon (RR' : relᵢ R R) (b1 b2 b1' b2': bool)
      (LEb1: is_true b1 -> is_true b1')
      (LEb2: is_true b2 -> is_true b2')
      (LERR: RR <3= RR'):
  @eqit I E _ _ RR b1 b2 <3= @eqit I E _ _ RR' b1' b2'.
Proof.
  pcofix self. pstep. intros i u v euv. punfold euv.
  red in euv |- *. induction euv; pclearbot; eauto 7 with paco.
Qed.

Global Instance Symmetric_eqit b : Symmetricᵢ RR -> Symmetricᵢ (@eqit I E _ _ RR b b).
Proof.
  red; intros. apply eqit_flip.
  eapply eqit_mon, H0; eauto.
Qed.

(*
Global Instance eq_sub_euttge:
  subrelation (@eq_itree I E _ _ RR) (euttge RR).
Proof.
  ginit. pcofix CIH. intros.
  punfold H0. gstep. red in H0 |- *.
  hinduction H0 before CIH; subst; econstructor; try inv CHECK; pclearbot; eauto 7 with paco.
Qed.

Global Instance euttge_sub_eutt:
  subrelation (@euttge E _ _ RR) (eutt RR).
Proof.
  ginit. pcofix CIH. intros.
  punfold H0. gstep. red in H0 |- *.
  hinduction H0 before CIH; subst; econstructor; pclearbot; eauto 7 with paco.
Qed.

Global Instance eq_sub_eutt:
  subrelation (@eq_itree E _ _ RR) (eutt RR).
Proof.
  red; intros. eapply euttge_sub_eutt. eapply eq_sub_euttge. apply H.
Qed.
*)

End eqit_gen.
Global Hint Resolve Reflexive_eqit_ Reflexive_eqit Reflexive_eqit_gen : reflexivity.

Instance geuttgen_cong_eqit {I E R1 R2}
         {RR1 : relᵢ R1 R1} {RR2 : relᵢ R2 R2} {RS : relᵢ R1 R2}
         b1 b2 r rg
         (LERR1 : forall i x x' y, RR1 i x x' -> RS i x' y -> RS i x y)
         (LERR2 : forall i x y y', RR2 i y y' -> RS i x y' -> RS i x y) i:
  Proper (eq_itree RR1 i ==> eq_itree RR2 i ==> flip impl)
         (gpaco3 (@eqit_ I E R1 R2 RS b1 b2 id) (eqitC RS b1 b2) r rg i).
  repeat intro. guclo eqit_clo_trans. econstructor; cycle -3; eauto.
  - eapply eqit_mon, H; eauto; discriminate.
  - eapply eqit_mon, H0; eauto; discriminate.
Qed.

Global Instance geuttgen_cong_eqit_eq {I E R1 R2 RS} b1 b2 r rg i :
  Proper (eq_itree eqᵢ i ==> eq_itree eqᵢ i ==> flip impl)
         (gpaco3 (@eqit_ I E R1 R2 RS b1 b2 id) (eqitC RS b1 b2) r rg i).
Proof.
  eapply geuttgen_cong_eqit; intros; cbv in H; subst; eauto.
Qed.

Global Instance geuttge_cong_euttge {I E R1 R2}
         {RR1 : relᵢ R1 R1} {RR2 : relᵢ R2 R2} {RS : relᵢ R1 R2} r rg
       (LERR1: forall i x x' y, RR1 i x x' -> RS i x' y -> RS i x y)
       (LERR2: forall i x y y', RR2 i y y' -> RS i x y' -> RS i x y) i :
  Proper (euttge RR1 i ==> eq_itree RR2 i ==> flip impl)
         (gpaco3 (@eqit_ I E R1 R2 RS true false id) (eqitC RS true false) r rg i).
Proof.
  repeat intro. guclo eqit_clo_trans.
Qed.

Global Instance geuttge_cong_euttge_eq {I E R1 R2 RS} r rg i:
  Proper (euttge eqᵢ i ==> eq_itree eqᵢ i ==> flip impl)
         (gpaco3 (@eqit_ I E R1 R2 RS true false id) (eqitC RS true false) r rg i).
Proof.
  eapply geuttge_cong_euttge; intros; cbv in H; subst; eauto.
Qed.

Global Instance geutt_cong_euttge {I E R1 R2}
         {RR1 : relᵢ R1 R1} {RR2 : relᵢ R2 R2} {RS : relᵢ R1 R2} r rg
       (LERR1: forall i x x' y, RR1 i x x' -> RS i x' y -> RS i x y)
       (LERR2: forall i x y y', RR2 i y y' -> RS i x y' -> RS i x y) i:
  Proper (euttge RR1 i ==> euttge RR2 i ==> flip impl)
         (gpaco3 (@eqit_ I E R1 R2 RS true true id) (eqitC RS true true) r rg i).
Proof.
  repeat intro. guclo eqit_clo_trans.
Qed.

Global Instance geutt_cong_euttge_eq {I E R1 R2 RS} r rg i :
  Proper (euttge eqᵢ i ==> euttge eqᵢ i ==> flip impl)
         (gpaco3 (@eqit_ I E R1 R2 RS true true id) (eqitC RS true true) r rg i).
Proof.
  eapply geutt_cong_euttge; intros; cbv in H; subst; eauto.
Qed.

Global Instance eqitgen_cong_eqit {I E R1 R2}
         {RR1 : relᵢ R1 R1} {RR2 : relᵢ R2 R2} {RS : relᵢ R1 R2} b1 b2 i
       (LERR1: forall i x x' y, RR1 i x x' -> RS i x' y -> RS i x y)
       (LERR2: forall i x y y', RR2 i y y' -> RS i x y' -> RS i x y):
  Proper (eq_itree RR1 i ==> eq_itree RR2 i ==> flip impl)
         (@eqit I E R1 R2 RS b1 b2 i).
Proof.
  ginit. intros. eapply geuttgen_cong_eqit; eauto. gfinal. eauto.
Qed.

Global Instance eqitgen_cong_eqit_eq {I E R1 R2 RS} b1 b2 i:
  Proper (eq_itree eqᵢ i ==> eq_itree eqᵢ i ==> flip impl)
         (@eqit I E R1 R2 RS b1 b2 i).
Proof.
  ginit. intros. rewrite H1, H0. gfinal. eauto.
Qed.

(* would need to write/port transitivity properties (eqit_trans)
Global Instance euttge_cong_euttge {I E R RS}
       (TRANS: Transitiveᵢ RS) i :
  Proper (euttge RS i ==> flip (euttge RS i) ==> flip impl)
         (@eqit I E R R RS true false i).
Proof.
  repeat intro. do 2 (eapply eqit_mon, eqit_trans; eauto using (trans_rcompose RS)).
Qed.

Global Instance euttge_cong_euttge_eq {E R}:
  Proper (euttge eq ==> flip (euttge eq) ==> flip impl)
         (@eqit E R R eq true false).
Proof.
  eapply euttge_cong_euttge; eauto using eq_trans.
Qed.
*)
