#! /bin/bash
# Wrapper for invoking MuVal for (non-)termination verification in accordance with the method specified for termCOMP 2025

set -euo pipefail

WORKING_DIR="/opt/coar"
COAR_EXE="/usr/local/bin/coar"
CONFIG_DIR="/opt/coar/config"
LLVM_BIN_PATH="/opt/llvm-3.6.2/bin"
DG_BIN_PATH="/usr/local/bin/dg/tools"

cd $WORKING_DIR

category=""
timeout=""
args_to_coar=()
while (( $# > 0 )); do
    case $1 in
    --name )
        echo "MuVal"
        exit
        ;;
    --timeout=* )
        export timeout="${1#--timeout=}"
        shift
        ;;
    --category=* )
        category="${1#--category=}"
        shift
        ;;
    *)
        args_to_coar+=("$1")
        shift
        ;;
    esac
done

src=""

for a in "${args_to_coar[@]}"; do
  case "$a" in
    *.c|*.ari)
      src="$a"
      ;;
  esac
done

if [[ -z "$src" ]]; then
  echo "no .c or .ari input found" >&2
  exit 2
fi

# echo "timeout=${timeout:-<none>}, category=${category:-<none>}"
# echo "args_to_coar=${args_to_coar:-<none>}"
case $category in
    Integer_Transition_Systems )
        base_name=$(basename -- "$src" .ari)

        [ -e "$base_name.smt2" ] && chmod a+rw "$base_name.smt2"
        its-conversion-static --to smt2 "$src" > "$base_name.smt2"

        $COAR_EXE -c "$CONFIG_DIR/solver/muval_term_comp_parallel_exc_tbq_ar.json" -p "pltsterm" "$base_name.smt2"
        ;;
    C )
        export PATH="$LLVM_BIN_PATH:$DG_BIN_PATH:$PATH"

        base_name=$(basename -- "$src" .c)

        [ -e "${base_name}_PointsToSets.txt" ] && chmod a+rw "${base_name}_PointsToSets.txt"
        [ -e "${base_name}_Metadata_Ptr2Arr.txt" ] && chmod a+rw "${base_name}_Metadata_Ptr2Arr.txt"
        [ -e "${base_name}_Ptr2Arr.c" ] && chmod a+rw "${base_name}_Ptr2Arr.c"
        Ptr2Arr "$src"

        [ -e "${base_name}_Ptr2Arr.bc" ] && chmod a+rw "${base_name}_Ptr2Arr.bc"
        clang -Wall -Wextra -c -emit-llvm -O0 "${base_name}_Ptr2Arr.c" -o "${base_name}_Ptr2Arr.bc"

        [ -e "${base_name}_tailcallelim.bc" ] && chmod a+rw "${base_name}_tailcallelim.bc"
        opt -mem2reg -tailcallelim "${base_name}_Ptr2Arr.bc" -o "${base_name}_tailcallelim.bc"

        [ -e "${base_name}.t2" ] && chmod a+rw "${base_name}.t2"
        [ -e "${base_name}_tailcallelim.ll" ] && chmod a+rw "${base_name}_tailcallelim.ll"
        llvm2kittel --dump-ll --no-slicing --eager-inline --t2 "${base_name}_tailcallelim.bc" > "${base_name}.t2"

        $COAR_EXE -c "$CONFIG_DIR/solver/muval_term_comp_parallel_exc_tbq_ar.json" -p "ltsterm" "${base_name}.t2"
        ;;
    C_Mod )
        export PATH="$LLVM_BIN_PATH:$DG_BIN_PATH:$PATH"

        base_name=$(basename -- "$src" .c)

        [ -e "${base_name}_PointsToSets.txt" ] && chmod a+rw "${base_name}_PointsToSets.txt"
        [ -e "${base_name}_Metadata_Ptr2Arr.txt" ] && chmod a+rw "${base_name}_Metadata_Ptr2Arr.txt"
        [ -e "${base_name}_Ptr2Arr.c" ] && chmod a+rw "${base_name}_Ptr2Arr.c"
        Ptr2Arr "$src"

        [ -e "${base_name}_Ptr2Arr_SemanticAugmentor.c" ] && chmod a+rw "${base_name}_Ptr2Arr_SemanticAugmentor.c"
        SemanticAugmentor "${base_name}_Ptr2Arr.c" "${base_name}_Metadata_Ptr2Arr.txt" --mode=only-nobv

        [ -e "${base_name}_Ptr2Arr_SemanticAugmentor.bc" ] && chmod a+rw "${base_name}_Ptr2Arr_SemanticAugmentor.bc"
        clang -Wall -Wextra -c -emit-llvm -O0 "${base_name}_Ptr2Arr_SemanticAugmentor.c" -o "${base_name}_Ptr2Arr_SemanticAugmentor.bc"

        [ -e "${base_name}_tailcallelim.bc" ] && chmod a+rw "${base_name}_tailcallelim.bc"
        opt -mem2reg -tailcallelim "${base_name}_Ptr2Arr_SemanticAugmentor.bc" -o "${base_name}_tailcallelim.bc"

        [ -e "${base_name}.t2" ] && chmod a+rw "${base_name}.t2"
        [ -e "${base_name}_tailcallelim.ll" ] && chmod a+rw "${base_name}_tailcallelim.ll"
        llvm2kittel --signedness-info=false --nondet-type-info=true --dump-ll --no-slicing --eager-inline --t2 "${base_name}_tailcallelim.bc" > "${base_name}.t2"

        $COAR_EXE -c "$CONFIG_DIR/solver/muval_term_comp_parallel_exc_tbq_ar.json" -p "ltsterm" "${base_name}.t2"
        ;;
    C_BV )
        export PATH="$LLVM_BIN_PATH:$DG_BIN_PATH:$PATH"

        base_name=$(basename -- "$src" .c)

        [ -e "${base_name}_PointsToSets.txt" ] && chmod a+rw "${base_name}_PointsToSets.txt"
        [ -e "${base_name}_Metadata_Ptr2Arr.txt" ] && chmod a+rw "${base_name}_Metadata_Ptr2Arr.txt"
        [ -e "${base_name}_Ptr2Arr.c" ] && chmod a+rw "${base_name}_Ptr2Arr.c"
        Ptr2Arr "$src"

        [ -e "${base_name}_Ptr2Arr.bc" ] && chmod a+rw "${base_name}_Ptr2Arr.bc"
        clang -Wall -Wextra -c -emit-llvm -O0 "${base_name}_Ptr2Arr.c" -o "${base_name}_Ptr2Arr.bc"

        [ -e "${base_name}_tailcallelim.bc" ] && chmod a+rw "${base_name}_tailcallelim.bc"
        opt -mem2reg -tailcallelim "${base_name}_Ptr2Arr.bc" -o "${base_name}_tailcallelim.bc"

        [ -e "${base_name}.t2" ] && chmod a+rw "${base_name}.t2"
        [ -e "${base_name}_tailcallelim.ll" ] && chmod a+rw "${base_name}_tailcallelim.ll"
        llvm2kittel --signedness-info=true --nondet-type-info=false --dump-ll --no-slicing --eager-inline --t2 "${base_name}_tailcallelim.bc" > "${base_name}.t2"

        [ -e "${base_name}_annotated.t2" ] && chmod a+rw "${base_name}_annotated.t2"
        TypeAnnotator "${base_name}_Ptr2Arr.c" "${base_name}_tailcallelim.ll" "${base_name}.t2" --mode=all

        $COAR_EXE -c "$CONFIG_DIR/solver/muval_term_comp_parallel_exc_tbq_ar.json" -p "ltstermbv" "${base_name}_annotated.t2"
        ;;
    C_Print )
        export PATH="$LLVM_BIN_PATH:$DG_BIN_PATH:$PATH"

        base_name=$(basename -- "$src" .c)

        [ -e "${base_name}_PointsToSets.txt" ] && chmod a+rw "${base_name}_PointsToSets.txt"
        [ -e "${base_name}_Metadata_Ptr2Arr.txt" ] && chmod a+rw "${base_name}_Metadata_Ptr2Arr.txt"
        [ -e "${base_name}_Ptr2Arr.c" ] && chmod a+rw "${base_name}_Ptr2Arr.c"
        Ptr2Arr "$src"

        [ -e "${base_name}_Ptr2Arr.bc" ] && chmod a+rw "${base_name}_Ptr2Arr.bc"
        clang -Wall -Wextra -c -emit-llvm -O0 "${base_name}_Ptr2Arr.c" -o "${base_name}_Ptr2Arr.bc"

        [ -e "${base_name}_tailcallelim.bc" ] && chmod a+rw "${base_name}_tailcallelim.bc"
        opt -mem2reg -tailcallelim "${base_name}_Ptr2Arr.bc" -o "${base_name}_tailcallelim.bc"

        [ -e "${base_name}.t2" ] && chmod a+rw "${base_name}.t2"
        [ -e "${base_name}_tailcallelim.ll" ] && chmod a+rw "${base_name}_tailcallelim.ll"
        llvm2kittel --dump-ll --no-slicing --eager-inline --t2 "${base_name}_tailcallelim.bc" > "${base_name}.t2"

        cat "${base_name}.t2"
        ;;
    C_Print_Mod )
        export PATH="$LLVM_BIN_PATH:$DG_BIN_PATH:$PATH"

        base_name=$(basename -- "$src" .c)

        [ -e "${base_name}_PointsToSets.txt" ] && chmod a+rw "${base_name}_PointsToSets.txt"
        [ -e "${base_name}_Metadata_Ptr2Arr.txt" ] && chmod a+rw "${base_name}_Metadata_Ptr2Arr.txt"
        [ -e "${base_name}_Ptr2Arr.c" ] && chmod a+rw "${base_name}_Ptr2Arr.c"
        Ptr2Arr "$src"

        [ -e "${base_name}_Ptr2Arr_SemanticAugmentor.c" ] && chmod a+rw "${base_name}_Ptr2Arr_SemanticAugmentor.c"
        SemanticAugmentor "${base_name}_Ptr2Arr.c" "${base_name}_Metadata_Ptr2Arr.txt" --mode=only-nobv

        [ -e "${base_name}_Ptr2Arr_SemanticAugmentor.bc" ] && chmod a+rw "${base_name}_Ptr2Arr_SemanticAugmentor.bc"
        clang -Wall -Wextra -c -emit-llvm -O0 "${base_name}_Ptr2Arr_SemanticAugmentor.c" -o "${base_name}_Ptr2Arr_SemanticAugmentor.bc"

        [ -e "${base_name}_tailcallelim.bc" ] && chmod a+rw "${base_name}_tailcallelim.bc"
        opt -mem2reg -tailcallelim "${base_name}_Ptr2Arr_SemanticAugmentor.bc" -o "${base_name}_tailcallelim.bc"

        [ -e "${base_name}.t2" ] && chmod a+rw "${base_name}.t2"
        [ -e "${base_name}_tailcallelim.ll" ] && chmod a+rw "${base_name}_tailcallelim.ll"
        llvm2kittel --signedness-info=false --nondet-type-info=true --dump-ll --no-slicing --eager-inline --t2 "${base_name}_tailcallelim.bc" > "${base_name}.t2"

        cat "${base_name}.t2"
        ;;
    C_Print_BV )
        export PATH="$LLVM_BIN_PATH:$DG_BIN_PATH:$PATH"

        base_name=$(basename -- "$src" .c)

        [ -e "${base_name}_PointsToSets.txt" ] && chmod a+rw "${base_name}_PointsToSets.txt"
        [ -e "${base_name}_Metadata_Ptr2Arr.txt" ] && chmod a+rw "${base_name}_Metadata_Ptr2Arr.txt"
        [ -e "${base_name}_Ptr2Arr.c" ] && chmod a+rw "${base_name}_Ptr2Arr.c"
        Ptr2Arr "$src"

        [ -e "${base_name}_Ptr2Arr.bc" ] && chmod a+rw "${base_name}_Ptr2Arr.bc"
        clang -Wall -Wextra -c -emit-llvm -O0 "${base_name}_Ptr2Arr.c" -o "${base_name}_Ptr2Arr.bc"

        [ -e "${base_name}_tailcallelim.bc" ] && chmod a+rw "${base_name}_tailcallelim.bc"
        opt -mem2reg -tailcallelim "${base_name}_Ptr2Arr.bc" -o "${base_name}_tailcallelim.bc"

        [ -e "${base_name}.t2" ] && chmod a+rw "${base_name}.t2"
        [ -e "${base_name}_tailcallelim.ll" ] && chmod a+rw "${base_name}_tailcallelim.ll"
        llvm2kittel --signedness-info=true --nondet-type-info=false --dump-ll --no-slicing --eager-inline --t2 "${base_name}_tailcallelim.bc" > "${base_name}.t2"

        [ -e "${base_name}_annotated.t2" ] && chmod a+rw "${base_name}_annotated.t2"
        TypeAnnotator "${base_name}_Ptr2Arr.c" "${base_name}_tailcallelim.ll" "${base_name}.t2" --mode=all

        cat "${base_name}_annotated.t2"
        ;;
    *)
        echo "no category specified. usage: solver --category=<category> <input file>"
        ;;
esac
