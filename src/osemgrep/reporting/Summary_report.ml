module OutJ = Semgrep_output_v1_t

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)
(*
  Partially translated from output.py
*)

(*****************************************************************************)
(* Helpers *)
(*****************************************************************************)

(*****************************************************************************)
(* Entry point *)
(*****************************************************************************)

let pp_summary ~respect_gitignore ~(maturity : Maturity.t) ~max_target_bytes
    ~skipped_groups ppf () : unit =
  let {
    Skipped_report.ignored = semgrep_ignored;
    include_ = include_ignored;
    exclude = exclude_ignored;
    size = file_size_ignored;
    always = _always_ignored;
    other = other_ignored;
    errors;
  } =
    skipped_groups
  in

  Fmt_.pp_heading ppf "Scan Summary";
  (* TODO
        if self.target_manager.baseline_handler:
            limited_fragments.append(
                "Scan was limited to files changed since baseline commit."
            )
  *)
  let out_limited =
    if respect_gitignore then
      (* # Each target could be a git repo, and we respect the git ignore
         # of each target, so to be accurate with this print statement we
         # need to check if any target is a git repo and not just the cwd
         targets_not_in_git = 0
         dir_targets = 0
         for t in self.target_manager.targets:
             if t.path.is_dir():
                 dir_targets += 1
                 try:
                     t.files_from_git_ls()
                 except (subprocess.SubprocessError, FileNotFoundError):
                     targets_not_in_git += 1
                     continue
         if targets_not_in_git != dir_targets: *)
      Some "Scan was limited to files tracked by git."
    else None
  in
  let opt_msg msg = function
    | [] -> None
    | xs -> Some (string_of_int (List.length xs) ^ " " ^ msg)
  in
  let out_skipped =
    let mb = string_of_int Stdlib.(max_target_bytes / 1000 / 1000) in
    List_.filter_map Fun.id
      [
        opt_msg "files not matching --include patterns" include_ignored;
        opt_msg "files matching --exclude patterns" exclude_ignored;
        opt_msg ("files larger than " ^ mb ^ " MB") file_size_ignored;
        opt_msg "files matching .semgrepignore patterns" semgrep_ignored;
        (match maturity with
        | Develop -> opt_msg "other files ignored" other_ignored
        | Default
        | Legacy
        | Experimental ->
            None);
      ]
  in
  let out_partial =
    opt_msg
      "files only partially analyzed due to a parsing or internal Semgrep error"
      errors
  in
  match (out_skipped, out_partial, out_limited, skipped_groups.ignored) with
  | [], None, None, [] -> ()
  | xs, parts, limited, _ignored -> (
      Fmt.pf ppf "Some files were skipped or only partially analyzed.@\n";
      Option.iter (fun txt -> Fmt.pf ppf "  %s@\n" txt) limited;
      Option.iter (fun txt -> Fmt.pf ppf "  Partially scanned: %s@\n" txt) parts;
      match xs with
      | [] -> ()
      | xs ->
          Fmt.pf ppf "  Scan skipped: %s.@\n" (String.concat ", " xs);
          Fmt.pf ppf
            "  For a full list of skipped files, run semgrep with the \
             --verbose flag.@\n")
