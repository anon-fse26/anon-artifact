#Execute: ~/Desktop/run_MuVal.sh

root_directory="$HOME/Desktop/liveness_analysis"

cd "$root_directory/Benchmarks"

while IFS= read -r path; do

    echo "Processing $path ..."

    path_postfix="${path#./}"
    path_postfix_prefix="${path_postfix%.*}"
    bc_file_path="${path_postfix_prefix}.bc"
    t2_file_path="${path_postfix_prefix}.t2"
    directory_path=$(dirname "$path_postfix")
    output_file_path="$directory_path/output.txt"

    search_path="/$path_postfix/"
    if [[ "$search_path" == *"/FSE/"* ]]; then
        timeout=1200
    elif [[ "$search_path" == *"/TermCOMP/"* ]]; then
        timeout=900
    else
        timeout=900
    fi

    docker run --rm --platform linux/amd64 -v "$root_directory":/liveness_analysis llvm2kittel-original /bin/bash -c " \
        cd /liveness_analysis && \
        clang -Wall -Wextra -c -emit-llvm -O0 Benchmarks/\"$path_postfix\" -o Benchmarks/\"$bc_file_path\" && \
        Tools/MuVal/llvm2kittel/build/llvm2kittel --dump-ll --no-slicing --eager-inline --t2 Benchmarks/\"$bc_file_path\" > Benchmarks/\"$t2_file_path\""

    start_time=$(gdate +%s%N)
    {
        timeout --kill-after=10 "$timeout" docker run --rm -v "$root_directory":/liveness_analysis muval-original /bin/bash -c " \
            cd /root/coar && \
            ./main.exe -c ./config/solver/muval_parallel_exc_tbq_ar.json -p ltsterm /liveness_analysis/Benchmarks/\"$t2_file_path\""
    } >> "$output_file_path" 2>&1

    end_time=$(gdate +%s%N)
    elapsed_time=$(((end_time - start_time) / 1000000))
    printf "Runtime: %d milliseconds" "$elapsed_time" >> "$output_file_path"

done < <(find . -type f \( -name "*.c" -o -name "*.cpp" \) | sort)