#Execute: ~/Desktop/run_AProVE.sh

root_directory="$HOME/Desktop/liveness_analysis"

cd "$root_directory/Benchmarks"

while IFS= read -r path; do

    echo "Processing $path ..."

    path_postfix="${path#./}"
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

    start_time=$(gdate +%s%N)
    {
        timeout --kill-after=10 "$timeout" docker run --rm \
            --platform linux/amd64 \
            -v "$root_directory":/liveness_analysis \
            --entrypoint java \
            aprove \
            -ea -jar /opt/aprove/aprove.jar \
            -m wst --bit-width 64 "/liveness_analysis/Benchmarks/$path_postfix"
    } >> "$output_file_path" 2>&1

    end_time=$(gdate +%s%N)
    elapsed_time=$(((end_time - start_time) / 1000000))
    printf "Runtime: %d milliseconds" "$elapsed_time" >> "$output_file_path"

done < <(find . -type f \( -name "*.c" -o -name "*.cpp" \) | sort)