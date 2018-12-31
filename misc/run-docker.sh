#docker build -t syscheck-test  .

rm -rf results

mkdir -p results

docker run -it --mount type=bind,source="$(pwd)",target=/source,readonly --mount type=bind,source="$(pwd)"/results,target=/results syscheck-test bash
