# CoAR: Collection of Automated Reasoners

* MuVal: A fixpoint logic validity checker based on pfwCSP solving
* PCSat: A CHC/pfwnCSP/SyGuS solver based on CEGIS

## Installation from source code

* Install opam2 (see [the official webpage](https://opam.ocaml.org/doc/Install.html)).
* Install ocaml-5.3.0:
  ```bash
  opam switch create 5.3.0
  ```
* Install dune:
  ```bash
  opam install dune
  ```
* Install required packages:
  ```bash
  opam install . --deps-only
  ```
  (You may also need to install `libblas-dev`, `liblapack-dev`, `libmpfr-dev`, `libgmp-dev`, `libglpk-dev`, `libffi-dev`, and `pkg-config`)
* Build:
  ```bash
  dune build main.exe
  ```
* Run:
  ```bash
  ./_build/default/main.exe -c <config_file> -p <problem_type> <target_file>
  ```
* Build & Run:
  ```bash
  dune exec main -- -c <config_file> -p <problem_type> <target_file>
  ```
* Please follow the instructions in `./script/fse2026/README.md`.

### Required OCaml packages:

* `core`
* `core_unix`
* `domainslib`
* `menhir`
* `ppx_deriving_yojson`
* `ocaml-compiler-libs`
* `ocamlgraph`
* `zarith`
* `z3`
* `minisat`
* `camlzip`

### External tools (optional):

- `hoice` (https://github.com/hopv/hoice)
- `clang` (https://clang.llvm.org/)
- `llvm2kittel` (https://github.com/addmai/llvm2kittel/tree/termcomp2025)
- `ltl3ba` (https://sourceforge.net/projects/ltl3ba/)

## Installation with Docker

```bash
docker pull docker.io/library/ubuntu:24.10
docker pull docker.io/ocaml/opam:ubuntu-24.10-ocaml-5.3
sudo docker build -t coar .
```
Please follow the instructions in `./script/fse2026/README.md`.
