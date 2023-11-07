(lang dune 3.5)

(name birru)

(generate_opam_files true)

(source
 (github frectonz/birru_cli))

(authors "frectonz")

(maintainers "frectonz")

(license MIT)

(package
 (name birru)
 (synopsis "A simple CLI tool the gets data from the Birru API.")
 (depends ocaml dune cohttp-lwt-unix yojson ANSITerminal))
