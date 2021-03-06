
Require Import Iron.SimplePCFa.Step.Prim.
Require Import Iron.SimplePCFa.Step.Frame.


(******************************************************************************)
(* Termination of an expression reduction in some context. *)
Inductive TERMS : stack -> exp -> Prop :=
 | RfLetPush
   :  forall fs t x1 x2
   ,  TERMS (fs :> FLet t x2) x1
   -> TERMS fs                (XLet t x1 x2)

 | RfLetPop
   :  forall fs t v x
   ,  TERMS fs                (substVX 0 v x)
   -> TERMS (fs :> FLet t x)  (XVal v)

 | RfStep
   :  forall fs x1 x2
   ,  STEPP x1 x2 -> TERMS fs x2
   -> TERMS fs x1

 (* A value in an empty context has terminated. *)
 | RfDone
   :  forall v
   ,  TERMS nil (XVal v).
Hint Constructors TERMS.


(* Termination of an expression reduction in an empty context. *)
Inductive TERM : exp -> Prop :=
 | RTerm
   : forall x
   , TERMS nil x -> TERM x.
Hint Constructors TERM.


(* Wrap a frame context around an expression.
   This converts the frame to its expression form. *)
Fixpoint wrap (fs: stack) (x1: exp) : exp :=
 match fs with
 | nil              => x1
 | f' :> FLet t1 x2 => wrap f' (XLet t1 x1 x2)
 end.


(* Reducing a term with an explicit frame is equivalent
   to wrapping the term with its frame and reducing that. *)
Lemma terms_wrap
 : forall f x
 , TERMS f x <-> TERM (wrap f x).
Proof.
 intros.
 split.

  intros. gen x.
  induction f; eauto.
   intros. induction x; simpl; destruct a; eauto.

  intros. gen x.
  induction f; intros.
   simpl in H. inverts H. auto.
   simpl in H. destruct a.
    lets D: IHf H.
    destruct x; inverts D; nope.
Qed.


(******************************************************************************)
(* Termination with STEPS *)
Lemma steps_terms_trans
 :  forall fs x1 x2
 ,  TERMS fs x1
 -> STEPS x1 x2
 -> TERMS fs x2.
Proof.
 intros.
 induction H0; eauto.

  gen fs.
  induction H0; intros; eauto.
  destruct x1; nope.
   inverts H0. assert (x2 = x0). admit. subst. auto.  (* determinism of STEPP *)
   inverts H0. skip. (* determinism ok *)
   inverts H0. skip. (* determinism ok *)

   SCase "XLet".
    eapply RfLetPush.
    inverts H. eauto. nope.

   SCase "XApp".
    inverts H.
    inverts H2. auto.
    inverts H.
    inverts H0.
Qed.
Hint Resolve steps_terms_trans.


(******************************************************************************)
(* Termination with STEPF *)
Lemma stepf_terms
 :  forall fs x v
 ,  STEPF  fs x nil (XVal v)
 -> TERMS  fs x.
Proof.
 intros. gen fs v. 
 induction x; intros;
  try (solve [inverts H; eauto]).
  Case "XVal".
   inverts H.
    eauto.
    eapply RfLetPop. rewritess. auto. 
Qed.


Lemma stepf_terms_expand_front
 :  forall fs1 x1 fs2 x2
 ,  STEPF fs1 x1 fs2 x2
 -> TERMS fs2 x2
 -> TERMS fs1 x1.
Proof.
 intros fs1 x1 fs2 x2 HS HT.
 induction HS; eauto.
Qed.


Lemma stepf_terms_trans
 :  forall x1 fs1 x2 fs2
 ,  TERMS  fs1 x1
 -> STEPF  fs1 x1 fs2 x2
 -> TERMS  fs2 x2.
Proof.
 intros.
 induction H0; eauto.
  (inverts H; eauto; nope).
Qed.


(******************************************************************************)
(* Termination with STEPLS *)
Lemma terms_stepls
 :  forall fs x
 ,  TERMS fs x
 -> exists v, STEPLS fs x nil (XVal v).
Proof.
 intros.
 induction H.
  destruct IHTERMS as [v].  eauto.
  destruct IHTERMS as [v0]. eauto.
  destruct IHTERMS as [v].  eauto.
  eauto.
Qed.
Hint Resolve terms_stepls.


Lemma terms_stepls_expand_front
 :  forall fs1 x1 fs2 x2
 ,  STEPLS fs1 x1 fs2 x2
 -> TERMS  fs2 x2
 -> TERMS  fs1 x1. 
Proof.
 intros.
 induction H.
  auto.
  eapply stepf_terms_expand_front; eauto.
Qed.


Lemma terms_stepls_expand_back
 :  forall x1 fs1 x2 fs2
 ,  STEPLS fs1 x1 fs2 x2
 -> TERMS  fs1 x1 
 -> TERMS  fs2 x2.
Proof.
 intros.
 induction H.
  eauto.
  eauto using stepf_terms_trans.
Qed.


(******************************************************************************)
Lemma terms_split
 :  forall fs1 fs2 x 
 ,  TERMS (fs1 >< fs2) x
 -> (exists v, STEPLS fs2 x nil (XVal v)
            /\ TERMS  fs1 (XVal v)).
Proof.
 intros. gen x. gen fs1.
 induction fs2; intros.

  Case "Nil".
   rrwrite (fs1 >< nil = fs1) in H.

   gen x.
   induction fs1; intros.
    SCase "Nil".
     lets HS: terms_stepls H. shift v. rip.

    SCase "Cons".
     destruct a.
     lets D: RfLetPush H.
     spec IHfs1 D.
     destruct IHfs1 as [v]. rip.

     assert (exists v1, STEPLS nil x nil (XVal v1)). 
      admit. (* from STEPSLS, binding exp reduces to some value *)

     destruct H0 as [v1].
     exists v1. rip.

     eapply terms_stepls_expand_back. eauto.
      eapply RfLetPop. admit. 
 
  Case "Cons".   
   rrwrite (fs1 >< (fs2 :> a) = (fs1 >< fs2) :> a) in H.
   destruct a.
   apply RfLetPush in H.
   lets D: IHfs2 H.
   destruct D as [v].
   exists v. rip.
   inverts H1.
    admit.
Qed.
