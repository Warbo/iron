
Require Import Iron.SimplePCFa.Step.Prim.
Require Import Iron.SimplePCFa.Value.


(* Frame stacks *)
(* Holds the continuation while a 'let' expression reduces the bound term. *)
Inductive frame : Type :=
 | FLet : ty -> exp -> frame.
Hint Constructors frame.

Definition stack := list frame.
Hint Unfold stack.


(* Single step reduction under a frame stack. *)
Inductive STEPF : stack -> exp -> stack -> exp -> Prop :=
 | SfStep
   :  forall fs x1 x2
   ,  STEPP    x1    x2
   -> STEPF fs x1 fs x2

 | SfPush
   :  forall fs t x1 x2
   ,  STEPF fs                (XLet t x1 x2)
            (fs :> FLet t x2) x1

 | SfPop
   :  forall fs x t v
   ,  STEPF (fs :> FLet t x)  (XVal v)
            fs                (substVX 0 v x).
Hint Constructors STEPF.


(** Left biased multi-step evaluation under a frame stack *)
Inductive STEPLS : stack -> exp -> stack -> exp -> Prop :=
 | SsNone
   :  forall fs x1
   ,  STEPLS fs x1 fs x1

 | SsCons
   :  forall fs1 x1 fs2 x2 fs3 x3
   ,  STEPF  fs1 x1 fs2 x2 -> STEPLS fs2 x2 fs3 x3
   -> STEPLS fs1 x1 fs3 x3.
Hint Constructors STEPLS.


(** Right biased multi-step evaluation under a frame stack *)
Inductive STEPRS : stack -> exp -> stack -> exp -> Prop :=
 | SrNone
   :  forall fs x1
   ,  STEPRS fs x1 fs x1

 | SrSnoc
   :  forall fs1 x1 fs2 x2 fs3 x3
   ,  STEPRS fs1 x1 fs2 x2 -> STEPF fs2 x2 fs3 x3 
   -> STEPRS fs1 x1 fs3 x3.
Hint Constructors STEPRS.

