open Core
open CoAR
open Common
open Common.Combinator

type problem =
  | PSAT  (** Boolean SAT Solving *)
  | PSMT  (** SMT Solving *)
  | PPCSP  (** pfwnCSP Satifiability Checking *)
  | PMuCLP  (** muCLP Validity Checking *)
  | PMuCLPInter  (** Interactive Conditional muCLP Validity Checking *)
  | PCLTL  (** LTL Verification of C Programs *)
  | PCCTL  (** CTL Verification of C Programs *)
  | PLTSSafe of (* BV mode *) bool
      (** Safety Verification of Labeled Transition Systems *)
  | PLTSNSafe of (* BV mode *) bool
      (** Non-Safety Verification of Labeled Transition Systems *)
  | PLTSTerm of (* BV mode *) bool
      (** Termination Verification of Labeled Transition Systems *)
  | PLTSNTerm of (* BV mode *) bool
      (** Non-Termination Verification of Labeled Transition Systems *)
  | PLTSMuCal of (* BV mode *) bool
      (** Modal mu-Calculus Model Checking of Labeled Transition Systems *)
  | PLTSRel of (* BV mode *) bool
      (** Relational Verification of Labeled Transition Systems *)
  | PLTSTermInter of (* BV mode *) bool
      (** Interactive Conditional (Non-)Termination Analysis of Labeled
          Transition Systems *)
  | PPLTSTerm
      (** Termination Verification of Pushdown Labeled Transition Systems *)
  | PPLTSNTerm
      (** Non-Termination Verification of Pushdown Labeled Transition Systems *)
[@@deriving show]

let problem =
  Command.Arg_type.create (fun problem ->
      let open Or_error in
      problem |> String.lowercase |> function
      | "sat" -> return PSAT
      | "smt" -> return PSMT
      | "chc" | "pcsp" | "pfwcsp" | "pfwncsp" -> return PPCSP
      | "muclp" -> return PMuCLP
      | "muclpinter" | "muclp-inter" -> return PMuCLPInter
      | "cltl" | "c-ltl" -> return PCLTL
      | "cctl" | "c-ctl" -> return PCCTL
      | "ltssafe" | "lts-safe" -> return (PLTSSafe false)
      | "ltssafebv" | "lts-safe-bv" -> return (PLTSSafe true)
      | "ltsnsafe" | "lts-nsafe" -> return (PLTSNSafe false)
      | "ltsnsafebv" | "lts-nsafe-bv" -> return (PLTSNSafe true)
      | "ltsterm" | "lts-term" -> return (PLTSTerm false)
      | "ltstermbv" | "lts-term-bv" -> return (PLTSTerm true)
      | "ltsnterm" | "lts-nterm" -> return (PLTSNTerm false)
      | "ltsntermbv" | "lts-nterm-bv" -> return (PLTSNTerm true)
      | "ltsmucal" | "lts-mucal" -> return (PLTSMuCal false)
      | "ltsmucalbv" | "lts-mucal-bv" -> return (PLTSMuCal true)
      | "ltsrel" | "lts-rel" -> return (PLTSRel false)
      | "ltsrelbv" | "lts-rel-bv" -> return (PLTSRel true)
      | "ltsterminter" | "lts-term-inter" -> return (PLTSTermInter false)
      | "ltsterminterbv" | "lts-term-inter-bv" -> return (PLTSTermInter true)
      | "pltsterm" | "plts-term" -> return PPLTSTerm
      | "pltsnterm" | "plts-nterm" -> return PPLTSNTerm
      | _ -> failwith (sprintf "invalid problem: %s" problem))

let default_config_file = "./config/solver/muval_parallel_exc_tbq_ar.json"

let cmd =
  Command.basic_spec ~summary:"CoAR: Collection of Automated Reasoners"
    Command.Spec.(
      empty
      +> anon ("filename" %: string)
      +> flag "--config"
           (optional_with_default default_config_file string)
           ~aliases:[ "-c" ]
           ~doc:
             (sprintf "<config> specify solver configuration file (default:%s)"
                default_config_file)
      +> flag "--problem"
           (optional_with_default (Or_error.return PMuCLP) problem)
           ~aliases:[ "-p" ]
           ~doc:
             "choose problem \
              [SAT/QSAT/DQSAT/HOSAT/SMT/HOMC/SyGuS/CHC/pCSP/pfwCSP/pfwnCSP/CHCMax/muCLP/muCLPInter/QmuCLP/CLTL/CCTL/LTSsafe/LTSnsafe/LTSterm/LTStermBV/LTSnterm/LTSntermBV/LTSmucal/LTSrel/LTStermInter/PLTSterm/PLTSnterm/ML] \
              (default: muCLP)"
      +> flag "--verbose" no_arg (* this option is obsolete *)
           ~aliases:[ "-v" ] ~doc:"enable verbose mode")

let load_solver_config prblm solver =
  let open Solver.Config in
  match load_config solver with
  | Error err -> Error err
  | Ok cfg -> (
      Or_error.return
      @@
      match cfg with
      | MuVal _
        when Stdlib.(
               prblm = PMuCLPInter
               || prblm = PLTSTermInter false
               || prblm = PLTSTermInter true) ->
          cfg
      | MuVal _
        when Stdlib.(
               prblm = PPCSP || prblm = PMuCLP || prblm = PCLTL || prblm = PCCTL
               || prblm = PLTSSafe false || prblm = PLTSSafe true
               || prblm = PLTSNSafe false || prblm = PLTSNSafe true
               || prblm = PLTSTerm false || prblm = PLTSTerm true
               || prblm = PLTSNTerm false || prblm = PLTSNTerm true
               || prblm = PLTSMuCal false || prblm = PLTSMuCal true
               || prblm = PLTSRel false || prblm = PLTSRel true
               || prblm = PPLTSTerm || prblm = PPLTSNTerm) ->
          cfg
      | (PCSat _ | SPACER _ | Hoice _) when Stdlib.(prblm = PPCSP) -> cfg
      | (MiniSat _ | Z3Sat _) when Stdlib.(prblm = PSAT) -> cfg
      | Z3Smt _ when Stdlib.(prblm = PSMT) -> cfg
      | _ ->
          failwith
          @@ sprintf "The specified solver does not support the problem %s"
               (show_problem prblm))

let load_sat filename =
  match Filename.split_extension filename with
  | _, Some ("dimacs" | "cnf") -> Ok (SAT.Problem.from_dimacs_file filename)
  | fn, Some "gz"
    when match Filename.split_extension fn with
         | _, Some ("dimacs" | "cnf") -> true
         | _ -> false ->
      Ok (SAT.Problem.from_gzipped_dimacs_file filename)
  | _ -> Or_error.unimplemented "load_sat"

let load_smt ~print filename =
  match snd (Filename.split_extension filename) with
  | Some "smt2" ->
      Ok (SMT.Smtlib2.from_smt2_file ~print ~inline:true (*ToDo*) filename)
  | _ -> Or_error.unimplemented "load_smt"

let load_pcsp ~print filename =
  match Filename.split_extension filename with
  | _, Some "smt2" ->
      Ok
        (PCSP.Parser.from_smt2_file ~print ~inline:true (*ToDo*)
           ~skolem_pred:true filename)
  | fn, Some "gz"
    when match Filename.split_extension fn with
         | _, Some "smt2" -> true
         | _ -> false ->
      Ok
        (PCSP.Parser.from_gzipped_smt2_file ~print ~inline:true (*ToDo*)
           ~skolem_pred:true filename)
  | _, Some "clp" -> Ok (PCSP.Parser.from_clp_file ~print filename)
  | _ -> Or_error.unimplemented "load_pcsp"

let load_muclp ~print filename =
  match snd (Filename.split_extension filename) with
  | Some "hes" -> MuCLP.Util.from_file ~print filename
  | _ -> Or_error.unimplemented "load_muclp"

let load_cltl ~print filename =
  match snd (Filename.split_extension filename) with
  | Some "c" -> C.Parser.from_cltl_file ~print filename
  | _ -> Or_error.unimplemented "load_cltl"

let load_cctl ~print filename =
  match snd (Filename.split_extension filename) with
  | Some "c" -> C.Parser.from_cctl_file ~print filename
  | _ -> Or_error.unimplemented "load_cctl"

let load_lts ~bv_mode filename =
  match snd (Filename.split_extension filename) with
  | Some "t2" -> LTS.Parser.from_file ~bv_mode filename
  | _ -> Or_error.unimplemented "load_lts"

let load_plts ~print filename =
  match snd (Filename.split_extension filename) with
  | Some "smt2" -> PLTS.Parser.from_file ~print filename
  | _ -> Or_error.unimplemented "load_plts"

let main filename solver problem verbose () =
  let open Or_error.Monad_infix in
  let module Debug =
    Debug.Make ((val Debug.Config.(if verbose then enable else disable))) in
  ok_exn
    ( problem >>= fun problem ->
      load_solver_config problem solver >>= fun cfg ->
      let module Config = struct
        let config = cfg
      end in
      let module Solver = Solver.Make (Config) in
      Debug.print
      @@ lazy
           (sprintf "*********** %s solving mode ************\n"
           @@ show_problem problem);
      match problem with
      | PSAT -> load_sat filename >>= Solver.solve_sat
      | PSMT -> load_smt ~print:Debug.print filename >>= Solver.solve_smt
      | PPCSP ->
          load_pcsp ~print:Debug.print filename
          >>= Solver.solve_pcsp ~filename:(Some filename)
      | PMuCLP -> load_muclp ~print:Debug.print filename >>= Solver.solve_muclp
      | PMuCLPInter ->
          load_muclp ~print:Debug.print filename
          >>= Solver.solve_muclp_interactive
      | PCLTL -> load_cltl ~print:Debug.print filename >>= Solver.solve_muclp
      | PCCTL -> load_cctl ~print:Debug.print filename >>= Solver.solve_muclp
      | PLTSSafe bv_mode ->
          load_lts ~bv_mode filename >>= fun lts ->
          Solver.solve_lts ~print:Debug.print (lts, LTS.Problem.Safe)
      | PLTSNSafe bv_mode ->
          load_lts ~bv_mode filename >>= fun lts ->
          Solver.solve_lts ~print:Debug.print (lts, LTS.Problem.NonSafe)
      | PLTSTerm bv_mode ->
          load_lts ~bv_mode filename >>= fun lts ->
          Solver.solve_lts ~print:Debug.print (lts, LTS.Problem.Term)
      | PLTSNTerm bv_mode ->
          load_lts ~bv_mode filename >>= fun lts ->
          Solver.solve_lts ~print:Debug.print (lts, LTS.Problem.NonTerm)
      | PLTSMuCal bv_mode ->
          load_lts ~bv_mode filename >>= fun lts ->
          Solver.solve_lts ~print:Debug.print (lts, LTS.Problem.MuCal)
      | PLTSRel bv_mode ->
          load_lts ~bv_mode filename >>= fun lts ->
          Solver.solve_lts ~print:Debug.print (lts, LTS.Problem.Rel)
      | PLTSTermInter bv_mode ->
          load_lts ~bv_mode filename >>= fun lts ->
          Solver.solve_lts_interactive ~print:Debug.print lts
      | PPLTSTerm ->
          load_plts ~print:Debug.print filename >>= fun plts ->
          Solver.solve_plts ~print:Debug.print (plts, PLTS.Problem.Term)
      | PPLTSNTerm ->
          load_plts ~print:Debug.print filename >>= fun plts ->
          Solver.solve_plts ~print:Debug.print (plts, PLTS.Problem.NonTerm) )

let () = Command_unix.run ~version:Version.version @@ cmd main
