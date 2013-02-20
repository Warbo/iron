
Require Export Iron.SystemF2Effect.Type.Exp.Base.
Require Export Iron.SystemF2Effect.Type.EquivT.
Require Export Iron.SystemF2Effect.Type.SubsT.
Require Export Iron.SystemF2Effect.Type.Operator.FlattenT.


Inductive EquivTs : kienv -> stprops -> list ty -> list ty -> ki -> Prop :=
 | EqsSum
   :  forall ke sp ts1 ts2 k
   ,  sumkind k
   -> Forall (fun t1 => KIND ke sp t1 k) ts1
   -> Forall (fun t2 => KIND ke sp t2 k) ts2
   -> Forall (fun t2 => In t2 ts1) ts2
   -> Forall (fun t1 => In t1 ts2) ts1
   -> EquivTs ke sp ts1 ts2 k.

Hint Constructors EquivTs.


Lemma equivTs_refl
 :  forall  ke sp ts k
 ,  sumkind k
 -> Forall (fun t => KIND ke sp t k) ts
 -> EquivTs ke sp ts ts k.
Proof.
 intros.
 induction ts.
  eapply EqsSum; auto.
  eapply EqsSum; auto.
   norm. norm.
Qed.


Lemma equivTs_sym
 :  forall ke sp ts1 ts2 k
 ,  sumkind k
 -> Forall (fun t => KIND ke sp t k) ts1
 -> Forall (fun t => KIND ke sp t k) ts2
 -> EquivTs ke sp ts1 ts2 k
 -> EquivTs ke sp ts2 ts1 k.
Proof.
 intros. inverts H2.
 eapply EqsSum; auto.
Qed. 


Lemma equivT_equivTs 
 :  forall  ke sp t1 t2 k
 ,  sumkind k
 -> EquivT  ke sp t1 t2 k
 -> EquivTs ke sp (flattenT t1) (flattenT t2) k.
Proof.
 intros.
 induction H0.
  eapply equivTs_refl; auto.
  eapply equivTs_sym;  auto.

  admit.                                         (* ok, need EquivTs trans *)

  Case "EqSumBot".
  { simpl. norm. 
    apply equivTs_refl; auto.
  }

  Case "EqSumIdemp".
  { simpl.
    eapply EqsSum; norm; auto.
    eapply in_app_split in H2.
     inverts H2; auto.
  }

  Case "EqSumComm".
  { simpl.
    eapply EqsSum; auto.
     norm.
     norm.
  }

  Case "EqSumAssoc".
  { simpl.
    eapply EqsSum; auto.
    - norm. 
      eapply in_app_split in H4. inverts H4.
      eapply in_app_split in H5. inverts H5.
      auto. auto. auto.
    - norm.
      eapply in_app_split in H4. inverts H4. auto.
      eapply in_app_split in H5. inverts H5. 
      auto. auto.
  }
Qed.