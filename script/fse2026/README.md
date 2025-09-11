# Artifact for FSE 2026 Submission
After creating the Docker image, convert it to an Apptainer image.

## Obtaining benchmarks (for testing)
If testing is to be performed afterward, clone the termCOMP benchmark repositories that are registered as submodules.
```bash
git submodule update benchmarks/term-comp/
git submodule update benchmarks/term-comp-ari/
```

## Creating the Docker image
Build the image for the FSE 2026 artifact based on the image built from the `Dockerfile` located at the root of the repository.
```bash
docker build -t coar .
docker build -f script/fse2026/Dockerfile -t fse2026 .
```

## Testing the Docker image
When starting the container using `docker compose`, bind mount the directories containing the benchmarks and test scripts used for testing at the same time.

```bash
docker compose -f script/fse2026/compose.yaml up -d
```

Solve the C category benchmarks using llvm2kittel and MuVal.

```bash
docker exec -it fse2026-solver-1 bash -c "script/fse2026/test_llvm2kittel.sh 2> /dev/null"
```

(Example output)

```
output of llvm2kittel (tail):
FROM: main_bb6;
TO: main_bb6_ret;

FROM: main_bb7;
v16 := varg_alloca.0.i - 1;
v17 := varg_alloca1.0.i + 1;
var__temp_varg_alloca.0.i := v16;
var__temp_varg_alloca1.0.i := v17;
TO: main_bb4;

solve using MuVal:
NO
```

## Conversion from a Docker image to an Apptainer image and testing
After converting the image, test the `solver` command.

(Testing contents)

- Check if `solver --name` can be invoked
- Solve one benchmark from the Integer_Transition_Systems category
- Solve one benchmark from the C category

```bash
./script/fse2026/create_apptainer.sh
```

(Example output)

```
INFO:    Starting build...
INFO:    Fetching OCI image...
INFO:    Extracting OCI image...
2025/08/03 17:00:55  warn rootless{root/coar/main.exe} ignoring (usually) harmless EPERM on setxattr "user.rootlesscontainers"
INFO:    Inserting Apptainer configuration...
INFO:    Creating SIF file...
[====================================================================================================================================================================================] 100 % 0s
INFO:    Build complete: /Remotes/fptprove/script/fse2026/coar.sif
Test of `solver --name`...
MuVal
Test for Integer_Transition_Systems category...
NO

Test for C category...
YES
```

## Run benchmark test for FSE 2026 submission
- C category
```bash
docker compose -f script/fse2026/compose.yaml up -d
> [+] Running 2/2
> ✔ fse2026:latest                  Built     0.0s 
> ✔ Container fse2026-solver-1  Running   0.0s

docker exec -itd fse2026-solver-1 script/fse2026/run_bench_c.sh
```

Results of benchmark test is writen in following files.

- `termcomp_bench_results/C_muval_"%Y-%m-%d_%H-%M-%S_error.log`: output from stderr
- `termcomp_bench_results/C_muval_"%Y-%m-%d_%H-%M-%S.csv`: benchmark result (YES/NO/timeout/abort)
- `termcomp_bench_results/C_muval_"%Y-%m-%d_%H-%M-%S_sorted.csv`: benchmark result, sorted