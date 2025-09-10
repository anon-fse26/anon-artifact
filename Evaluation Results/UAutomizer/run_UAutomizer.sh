#Execute: ~/Desktop/run_UAutomizer.sh

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
        docker run --rm -v "$root_directory":/liveness_analysis uautomizer /bin/bash -c "
            cd /opt/uautomizer/config && \
            ln -s svcomp-Termination-64bit-Automizer_Default.epf svcomp-Termination-64bit-Automizer_Bitvector.epf && \
            cd /liveness_analysis && \
            timeout "$timeout" python3 /opt/uautomizer/Ultimate.py --spec Tools/UAutomizer/termination.prp --file Benchmarks/\"$path_postfix\" --architecture 64bit"
    } >> "$output_file_path" 2>&1

    end_time=$(gdate +%s%N)
    elapsed_time=$(((end_time - start_time) / 1000000))
    printf "Runtime: %d milliseconds" "$elapsed_time" >> "$output_file_path"

done < <(find . -type f \( -name "*.c" -o -name "*.cpp" \) | sort)