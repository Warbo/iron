
Require Export Iron.Language.SystemF2Effect.Type.
Require Export Iron.Language.SystemF2Effect.Value.Exp.
Require Export Iron.Language.SystemF2Effect.Value.Wf.
Require Export Iron.Language.SystemF2Effect.Value.Lift.


(* Store Environment holds the types of locations. *)
Definition stenv := list ty.


(* Types of Value expressions *)
Inductive TYPEV : kienv -> tyenv -> stenv -> val -> ty -> Prop := 
  | TvVar
    :  forall ke te se i t
    ,  get i te = Some t
    -> TYPEV ke te se (VVar i) t 

  | TvLoc 
    :  forall ke te se i r t
    ,  get i se  = Some (tRef r t)
    -> TYPEV ke te se (VLoc i) (tRef r t)

  | TvLam
    :  forall ke te se t1 t2 x2 e2
    ,  KIND ke t1 KData
    -> TYPEX ke (te :> t1) se x2 t2 e2
    -> TYPEV ke te se (VLam t1 x2) (tFun t1 e2 t2)

  | TvLAM
    :  forall ke te se k1 t2 x2
    ,  TYPEX (ke :> k1) (liftTE 0 te) (liftTE 0 se) x2 t2 (TBot KEffect)
    -> TYPEV ke         te            se            (VLAM k1 x2) (TForall k1 t2)

  | TvConstNat
    :  forall ke te se n
    ,  TYPEV ke te se (VConst (CNat n))  tNat

  | TvConstBool
    :  forall ke te se b
    ,  TYPEV ke te se (VConst (CBool b)) tBool


  with TYPEX : kienv -> tyenv -> stenv -> exp -> ty -> ty -> Prop :=
  | TxVal
    :  forall ke te se v1 t1
    ,  TYPEV ke te se v1        t1
    -> TYPEX ke te se (XVal v1) t1 (TBot KEffect)

  | TxLet
    :  forall ke te se t1 x1 t2 x2 e1 e2
    ,  KIND  ke t1 KData
    -> TYPEX ke te         se x1 t1 e1
    -> TYPEX ke (te :> t1) se x2 t2 e2
    -> TYPEX ke te         se (XLet t1 x1 x2) t2 (TSum e1 e2)

  | TxApp
    :  forall ke te se t11 t12 v1 v2 e1
    ,  TYPEV ke te se v1 (tFun t11 e1 t12) 
    -> TYPEV ke te se v2 t11
    -> TYPEX ke te se (XApp v1 v2) t12 e1

  | TvAPP
    :  forall ke te se v1 k11 t12 t2
    ,  TYPEV ke te se v1 (TForall k11 t12)
    -> KIND  ke t2 k11
    -> TYPEX ke te se (XAPP v1 t2) (substTT 0 t2 t12) (TBot KEffect)

  (* Store Operators *)
  | TxNew
    :  forall ke te se x t tL e eL
    ,  lowerTT 0 t = Some tL
    -> lowerTT 0 e = Some eL
    -> TYPEX (ke :> KRegion) (liftTE 0 te) (liftTE 0 se) x        t  e
    -> TYPEX ke              te             se           (XNew x) tL eL
    (* TODO: As it stands this should be sound and go through the proof,
             but need to cut effects on new region from 'e' before lowering
             otherwise the body can't actually use the new region *)

  | TxUse
    :  forall ke te se n x t e
    ,  TYPEX ke te se x t e
    -> TYPEX ke te se (XUse n x) t e
    (* TODO: cut effects due to the bound region variable *)

  | TxOpAlloc 
    :  forall ke te se r1 v2 t2
    ,  KIND  ke r1 KRegion
    -> TYPEV ke te se v2 t2
    -> TYPEX ke te se (XAlloc r1 v2) (tRef r1 t2) (tAlloc r1)

  | TxOpRead
    :  forall ke te se v1 r1 t2
    ,  KIND  ke r1 KRegion
    -> TYPEV ke te se v1 (tRef r1 t2)
    -> TYPEX ke te se (XRead r1 v1)     t2    (tRead r1)

  | TxOpWrite
    :  forall ke te se v1 v2 r1 t2
    ,  KIND  ke r1 KRegion
    -> TYPEV ke te se v1 (tRef r1 t2)
    -> TYPEV ke te se v2 t2
    -> TYPEX ke te se (XWrite r1 v1 v2) tUnit (tWrite r1)

  (* Primtive Operators *)
  | TxOpSucc
    :  forall ke te se v1
    ,  TYPEV ke te se v1 tNat
    -> TYPEX ke te se (XOp1 OSucc v1)   tNat (TBot KEffect)

  | TxOpIsZero
    :  forall ke te se v1
    ,  TYPEV ke te se v1 tNat
    -> TYPEX ke te se (XOp1 OIsZero v1) tBool (TBot KEffect).

Hint Constructors TYPEV.
Hint Constructors TYPEX.


(* Invert all hypothesis that are compound typing statements. *)
Ltac inverts_type :=
 repeat 
  (match goal with 
   | [ H: TYPEV _ _ _ (VVar   _)     _      |- _ ] => inverts H
   | [ H: TYPEV _ _ _ (VLoc   _)     _      |- _ ] => inverts H
   | [ H: TYPEV _ _ _ (VLam   _ _)   _      |- _ ] => inverts H
   | [ H: TYPEV _ _ _ (VLAM   _ _)   _      |- _ ] => inverts H
   | [ H: TYPEV _ _ _ (VConst _)     _      |- _ ] => inverts H
   | [ H: TYPEX _ _ _ (XVal   _)     _ _    |- _ ] => inverts H
   | [ H: TYPEX _ _ _ (XLet   _ _ _) _ _    |- _ ] => inverts H 
   | [ H: TYPEX _ _ _ (XApp   _ _)   _ _    |- _ ] => inverts H 
   | [ H: TYPEX _ _ _ (XAPP   _ _)   _ _    |- _ ] => inverts H 
   | [ H: TYPEX _ _ _ (XNew   _) _ _        |- _ ] => inverts H
   | [ H: TYPEX _ _ _ (XUse   _ _) _ _      |- _ ] => inverts H
   | [ H: TYPEX _ _ _ (XAlloc _ _)   _ _    |- _ ] => inverts H
   | [ H: TYPEX _ _ _ (XRead  _ _)   _ _    |- _ ] => inverts H
   | [ H: TYPEX _ _ _ (XWrite _ _ _) _ _    |- _ ] => inverts H
   | [ H: TYPEX _ _ _ (XOp1   _ _)   _ _    |- _ ] => inverts H 
   end).


(********************************************************************)
(* Uniqueness of typing *)
Lemma type_unique
 :  forall ke te se x t1 e1 t2 e2
 ,  TYPEX ke te se x t1 e1
 -> TYPEX ke te se x t2 e2
 -> t1 = t2 /\ e1 = e2.
Proof.
 intros. gen ke te se t1 e1 t2 e2.
 induction x using exp_mutind with 
  (PV := fun v1 => forall ke te se t1 t1'
      ,  TYPEV ke te se v1 t1
      -> TYPEV ke te se v1 t1'
      -> t1 = t1');
  intros; 
   try (solve [inverts_type; try congruence]);
   inverts_type; auto.

 Case "VLam".
  spec IHx H8 H9. burn.

 Case "VLAM".
  spec IHx H7 H6. burn.

 Case "XVal".
  spec IHx H5 H4. burn.

 Case "XLet".
  spec IHx1 H10 H12.
  spec IHx2 H11 H13. 
  rip.

 Case "XApp".
  spec IHx  H6 H5.
  spec IHx0 H9 H10.
  subst.
  inverts IHx. auto.

 Case "VAPP". 
  spec IHx H6 H5.
  inverts IHx.
  auto.

 Case "XNew".
  spec IHx H7 H9.
  rip.

 Case "XUse".
  spec IHx H8 H7.
  rip.

 Case "XAlloc".
  spec IHx H9 H10.
  subst. burn.

 Case "XRead".
  spec IHx H9 H10.
  inverts IHx. auto.
Qed.


(********************************************************************)
(* A well typed expression is well formed *)
Theorem type_wfX
 :  forall ke te se x t e
 ,  TYPEX ke te se x t e
 -> wfX (length ke) (length te) (length se) x.
Proof.
 intros. gen ke te se t e.
 induction x using exp_mutind with 
  (PV := fun v => forall ke te se t1
      ,  TYPEV ke te se v t1
      -> wfV (length ke) (length te) (length se) v);
   rip; inverts_type; try burn.

 Case "VLam".
  spec IHx H7. burn.

 Case "VLAM".
  eapply WfV_VLAM.
  spec IHx H6.
  rrwrite (length (ke :> k) = S (length ke)) in IHx.
  rewrite <- length_liftTE in IHx.
  rewrite <- length_liftTE in IHx.
  auto.

 Case "XLet".
  spec IHx1 H9.
  spec IHx2 H10.
  burn.

 Case "XNew".
  eapply WfX_XNew.
  spec IHx H6.
  rrwrite (length (ke :> KRegion) = S (length ke)) in IHx.
  rewrite <- length_liftTE in IHx.
  rewrite <- length_liftTE in IHx.
  burn.
Qed.
Hint Resolve type_wfX.


(********************************************************************)
(* Weakening Kind Env in Type Judgement. *)
Lemma type_kienv_insert
 :  forall ix ke te se x1 t1 e1 k2
 ,  TYPEX ke te se x1 t1 e1
 -> TYPEX (insert ix k2 ke) (liftTE ix te)   (liftTE ix se) 
          (liftTX ix x1)    (liftTT 1 ix t1) (liftTT 1 ix e1).
Proof.
 intros. gen ix ke te se t1 e1 k2.
 induction x1 using exp_mutind with 
  (PV := fun v => forall ix ke te se k2 t3
               ,  TYPEV ke te se v t3
               -> TYPEV (insert ix k2 ke) (liftTE ix te)   (liftTE ix se)
                        (liftTV ix v)     (liftTT 1 ix t3));
   intros; inverts_type; simpl; eauto.

 Case "VVar".
  apply TvVar; auto.
  apply get_map; auto.

 Case "VLoc".
  eapply TvLoc; eauto.
  rrwrite ( tRef (liftTT 1 ix r) (liftTT 1 ix t)
          = liftTT 1 ix (tRef r t)).
  apply get_map; auto.

 Case "VLam".
  apply TvLam.
   apply kind_kienv_insert. auto.
   rrwrite ( liftTE ix te :> liftTT 1 ix t
           = liftTE ix (te :> t)).
   spec IHx1 H7.
   burn.

 Case "VLAM".
  eapply TvLAM. 
  rewrite insert_rewind. 
  rewrite (liftTE_liftTE 0 ix).
  rewrite (liftTE_liftTE 0 ix).
  rrwrite (TBot KEffect = liftTT 1 (S ix) (TBot KEffect)).
  eauto.

 Case "XLet".
  apply TxLet.
   auto using kind_kienv_insert.
   eauto.
   rrwrite ( liftTE ix te :> liftTT 1 ix t
           = liftTE ix (te :> t)).
   eauto.

 Case "XApp".
  eapply TxApp.
   eapply IHx1 in H5. simpl in H5. eauto.
   eapply IHx0 in H8. eauto.

 Case "XAPP".
  rewrite (liftTT_substTT' 0 ix). 
  simpl.
  eapply TvAPP.
  eapply (IHx1 ix) in H5. simpl in H5. eauto.
  auto using kind_kienv_insert.

 Case "XNew".
  eapply TxNew 
   with (t := liftTT 1 (S ix) t)
        (e := liftTT 1 (S ix) e).
  admit. admit.                    (* looks reasonable *)
  rewrite insert_rewind.
  rewrite (liftTE_liftTE 0 ix).
  rewrite (liftTE_liftTE 0 ix).
  auto.

 Case "XAlloc".
  eapply TxOpAlloc; eauto using kind_kienv_insert.

 Case "XRead".
  eapply TxOpRead;  eauto using kind_kienv_insert.
  rrwrite ( tRef (liftTT 1 ix r) (liftTT 1 ix t1)
          = liftTT 1 ix (tRef r t1)).
  eauto.

 Case "XWrite".
  eapply TxOpWrite; eauto using kind_kienv_insert.
  eapply IHx1 in H9. simpl in H9. eauto.
  eapply IHx1 in H7. eauto.

 Case "XIsZero".
  eapply TxOpIsZero.
  eapply IHx1 in H7. eauto.
Qed.


Lemma type_kienv_weaken1
 :  forall ke te se x1 t1 e1 k2
 ,  TYPEX ke te se x1 t1 e1
 -> TYPEX (ke :> k2)    (liftTE 0 te)   (liftTE 0 se) 
          (liftTX 0 x1) (liftTT 1 0 t1) (liftTT 1 0 e1).
Proof.
 intros.
 assert (ke :> k2 = insert 0 k2 ke) as HI.
  simpl. destruct ke; auto.
 rewrite HI.
 eapply type_kienv_insert; auto.
Qed.


Lemma typev_kienv_weaken1
 :  forall ke te se v1 t1 k2
 ,  TYPEV  ke te se v1 t1
 -> TYPEV (ke :> k2)    (liftTE 0 te) (liftTE 0 se)
          (liftTV 0 v1) (liftTT 1 0 t1).
Proof.
 intros.
 have HX: (TYPEX ke te se (XVal v1) t1 (TBot KEffect)).
 eapply type_kienv_weaken1 in HX.
 simpl in HX.
 inverts HX. eauto.
Qed.


(********************************************************************)
(* Weakening Type Env in Type Judgement.
   We can insert a new type into the type environment, provided we
   lift existing references to types higher in the stack across
   the new one. *)
Lemma type_tyenv_insert
 :  forall ke te se ix x t1 e1 t2
 ,  TYPEX ke te se x t1 e1
 -> TYPEX ke (insert ix t2 te) se (liftXX 1 ix x) t1 e1.
Proof.
 intros. gen ix ke se te t1 e1 t2.
 induction x using exp_mutind with 
  (PV := fun v => forall ix ke se te t1 t2
      ,  TYPEV ke te se v t1 
      -> TYPEV ke (insert ix t2 te) se (liftXV 1 ix v) t1)
  ; intros; inverts_type; simpl; eauto.

 Case "VVar".
  nnat; lift_cases; burn.

 Case "VLam".
  apply TvLam; eauto.
  rewrite insert_rewind. auto.

 Case "VLAM".
  apply TvLAM.
  assert ( liftTE 0 (insert ix t2 te)
         = insert ix (liftTT 1 0 t2) (liftTE 0 te)).
   unfold liftTE. rewrite map_insert. auto.
   rewritess. eauto.

 Case "XLet".
  apply TxLet; eauto. 
  rewrite insert_rewind. eauto.

 Case "XNew".
  eapply TxNew with (t := t) (e := e); eauto.
  assert ( liftTE 0 (insert ix t2 te)
         = insert ix (liftTT 1 0 t2) (liftTE 0 te)).
   unfold liftTE. rewrite map_insert. auto.
   rewritess. eauto.
Qed. 


(* We can push a new type onto the environment stack provided
   we lift references to existing types across the new one. *)
Lemma type_tyenv_weaken1
 :  forall ke te se x t1 e1 t2
 ,  TYPEX ke te se x t1 e1
 -> TYPEX ke (te :> t2) se (liftXX 1 0 x) t1 e1.
Proof.
 intros.
 rrwrite (te :> t2 = insert 0 t2 te).
 burn using type_tyenv_insert.
Qed.


(* We can push a new type into the enviroment of a type-of-value 
   judgement provided we lift references to existing types across
   the new one *)
Lemma typev_tyenv_weaken1
 :  forall ke te se v t1 t2
 ,  TYPEV ke te se v t1
 -> TYPEV ke (te :> t2) se (liftXV 1 0 v) t1.
Proof.
 intros.
 have HX: (TYPEX ke te se (XVal v) t1 (TBot KEffect)).
 eapply type_tyenv_weaken1 in HX.
 simpl in HX. inverts HX. eauto.
Qed.


(* We can several new types onto the environment stack provided
   we lift referenes to existing types across the new one. *)
Lemma type_tyenv_weaken_append
 :  forall ke te te' se x t1 e1
 ,  TYPEX ke te se x t1 e1
 -> TYPEX ke (te >< te') se (liftXX (length te') 0 x) t1 e1.
Proof.
 intros.
 induction te'; simpl.
  burn.

  rrwrite (S (length te') = length te' + 1).
  rrwrite (length te' + 1 = 1 + length te').
  rewrite <- liftXX_plus.
  eapply type_tyenv_weaken1.
  burn.
Qed.


(********************************************************************)
(* Weakening Store Typing in Type Judgement. *)
Lemma typex_stenv_snoc 
 :  forall ke te se t2 x t1 e1
 ,  closedT t2
 -> TYPEX ke te se         x t1 e1
 -> TYPEX ke te (t2 <: se) x t1 e1.
Proof.
 intros. gen ke te se t1 e1 t2.
 induction x using exp_mutind with 
  (PV := fun v => forall ke te se t1 t2
      ,  closedT t2
      -> TYPEV ke te se         v t1
      -> TYPEV ke te (t2 <: se) v t1)
  ; intros; inverts_type; eauto.

 Case "VLAM".
  eapply TvLAM.
  spec IHx H7 H. clear H7.
  unfold liftTE in *.
  simpl. norm. 
  rrwrite (liftTT 1 0 t2 = t2).
  auto.

 Case "XNew".
  eapply TxNew with (t := t) (e := e); eauto.
  spec IHx H7 H. clear H7.
  unfold liftTE in *.
  simpl. norm.
  rrwrite (liftTT 1 0 t2 = t2).
  auto.
Qed.
Hint Resolve typex_stenv_snoc.


Lemma typex_stenv_weaken
 :  forall ke te se1 se2 x t1 e1
 ,  Forall closedT se2
 -> TYPEX  ke te  se1         x t1 e1
 -> TYPEX  ke te (se2 >< se1) x t1 e1.
Proof.
 intros. gen ke te se1.
 induction se2; intros.
  burn.
  rrwrite ((se2 :> a) >< se1 = se2 >< (a <: se1)).
  inverts H. rip.
Qed.
Hint Resolve typex_stenv_weaken.


Lemma typex_stenv_extends
 :  forall ke te se1 se2 x t1 e1
 ,  Forall closedT se2
 -> extends se2 se1
 -> TYPEX ke te se1 x t1 e1
 -> TYPEX ke te se2 x t1 e1.
Proof.
 intros.
 unfold extends in *.
 destruct H0 as [se3]. subst.
 eapply typex_stenv_weaken; auto.
  eauto.
Qed.
Hint Resolve typex_stenv_extends.


Lemma typev_stenv_extends
 :  forall ke te se1 se2 v t1
 ,  Forall closedT se2
 -> extends se2 se1
 -> TYPEV ke te se1 v t1
 -> TYPEV ke te se2 v t1.
Proof.
 intros.
 unfold extends in *.
 destruct H0 as [se3]. subst.
 assert (TYPEX ke te (se3 >< se1) (XVal v) t1 (TBot KEffect)) as HX.
  eauto.
 inverts HX. auto.
Qed.
Hint Resolve typex_stenv_extends.
