#!/usr/bin/env bash
set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TMPDIR="$HOME"
ITERATIVE_BENCH_FILE=$(mktemp --tmpdir)
VECTORIZED_BENCH_FILE=$(mktemp --tmpdir)
early_exit() {
	{ rm "$ITERATIVE_BENCH_FILE"; rm "$VECTORIZED_BENCH_FILE"; } > /dev/null 2>&1
	echo "Error. Cannot grade your assignment" >&2
}
errecho() {
	echo "$@" >&2
}
trap 'early_exit' EXIT
echo -e "\033[0;32mPlease wait patiently while the autograder runs. It may take some time and not print anything.\033[0m"
cd "$SCRIPT_DIR" >/dev/null
[ -f "iterative.c" ] || { errecho "iterative.c is not present. Couldn't grade your assignment."; exit 1; }
ISHA=$(sha256sum "iterative.c" | cut -d' ' -f1)
make > /dev/null 2>&1 || { errecho "Failed to run make. Can't grade your assignment."; exit 1; }
./test_novec 2>&1 || { errecho "test_novec failed. Can't grade your assignment."; exit 1; }
./test_vec 2>&1 || { errecho "test_vec failed. Can't grade your assignment."; exit 1; }
./test_iterative 2>&1 || { errecho "test_iterative failed. Can't grade your assignment."; exit 1; }
./benchmark_iterative > "$ITERATIVE_BENCH_FILE"
./benchmark_vec > "$VECTORIZED_BENCH_FILE"
[ "$(< "$ITERATIVE_BENCH_FILE" wc -l)" -eq 36 ] || { errecho "benchmark_iterative didn't output the expected number of lines. Can't grade your assignment."; exit 1; }
[ "$(< "$VECTORIZED_BENCH_FILE" wc -l)" -eq 36 ] || { errecho "benchmark_vec didn't output the expected number of lines. Can't grade your assignment."; exit 1; }
mapfile -t ARRAYMIN_VEC_NUMS < <(grep Arraymin "$VECTORIZED_BENCH_FILE" | cut -d' ' -f4)
mapfile -t MININDEX_VEC_NUMS < <(grep Minindex "$VECTORIZED_BENCH_FILE" | cut -d' ' -f4)
mapfile -t ARRAYMIN_ITERATIVE_NUMS < <(grep Arraymin "$ITERATIVE_BENCH_FILE" | cut -d' ' -f4)
mapfile -t MININDEX_ITERATIVE_NUMS < <(grep Minindex "$ITERATIVE_BENCH_FILE" | cut -d' ' -f4)
LEN=18
[ ${#ARRAYMIN_VEC_NUMS[@]} -eq $LEN ] || { errecho "Malformed benchmark_vec output. Can't grade your assignment."; exit 1; }
[ ${#MININDEX_VEC_NUMS[@]} -eq $LEN ] || { errecho "Malformed benchmark_vec output. Can't grade your assignment."; exit 1; }
[ ${#ARRAYMIN_ITERATIVE_NUMS[@]} -eq $LEN ] || { errecho "Malformed benchmark_iterative output. Can't grade your assignment."; exit 1; }
[ ${#MININDEX_ITERATIVE_NUMS[@]} -eq $LEN ] || { errecho "Malformed benchmark_iterative output. Can't grade your assignment."; exit 1; }
SCORE=0
EXPLAINATORY_MESSAGE=""
cnt=0
for ((i=0; i < LEN; i++)); do
	iterative_arrmin_score=${ARRAYMIN_ITERATIVE_NUMS[i]}
	vectorized_arrmin_score=${ARRAYMIN_VEC_NUMS[i]}
	(( vectorized_arrmin_score <= iterative_arrmin_score )) && ((cnt++)) || true
done
((cnt <= 3)) && ((SCORE+=25)) || EXPLAINATORY_MESSAGE+=$'\t- Lost 25 points because more than three iterative arraymin cycles/op measurements were greater-than-or-equal-to the corresponding vectorized arraymin cycles/op measurements\n'
cnt=0
for ((i=0; i < LEN; i++)); do
	iterative_minindex_score=${MININDEX_ITERATIVE_NUMS[i]}
	vectorized_minindex_score=${MININDEX_VEC_NUMS[i]}
	(( vectorized_minindex_score <= iterative_minindex_score )) && ((cnt++)) || true
done
((cnt <= 3)) && ((SCORE+=25)) || EXPLAINATORY_MESSAGE+=$'\t- Lost 25 points because more than three iterative minindex cycles/op measurements were greater-than-or-equal-to the corresponding vectorized minindex cycles/op measurements\n'
mapfile -t ARRAYMIN_ITERATIVE_CYC_P_ELEM < <(grep Arraymin "$ITERATIVE_BENCH_FILE" | cut -d' ' -f6)
mapfile -t MININDEX_ITERATIVE_CYC_P_ELEM < <(grep Minindex "$ITERATIVE_BENCH_FILE" | cut -d' ' -f6)
[ ${#ARRAYMIN_ITERATIVE_CYC_P_ELEM[@]} -eq $LEN ] || { errecho "Malformed benchmark_iterative output. Can't grade your assignment."; exit 1; }
[ ${#MININDEX_ITERATIVE_CYC_P_ELEM[@]} -eq $LEN ] || { errecho "Malformed benchmark_iterative output. Can't grade your assignment."; exit 1; }
(( $( echo "${ARRAYMIN_ITERATIVE_CYC_P_ELEM[1]} < 0.65" | bc -l ) )) &&
(( $(echo "${ARRAYMIN_ITERATIVE_CYC_P_ELEM[14]} < 0.10" | bc -l) )) && ((SCORE+=25)) || EXPLAINATORY_MESSAGE+=$'\t- Lost 25 points because iterative arraymin cycles/element benchmarks did not meet cutoffs\n'
(( $( echo "${MININDEX_ITERATIVE_CYC_P_ELEM[1]} < 1.65" | bc -l ) )) &&
(( $(echo "${MININDEX_ITERATIVE_CYC_P_ELEM[11]} < 0.15" | bc -l) )) &&
(( $(echo "${MININDEX_ITERATIVE_CYC_P_ELEM[16]} < 0.40" | bc -l) )) && ((SCORE+=25)) || EXPLAINATORY_MESSAGE+=$'\t- Lost 25 points because iterative minindex cycles/element benchmarks did not meet cutoffs\n'
cat <<EOF
Total Score: ${SCORE}%
$EXPLAINATORY_MESSAGE
EOF
echo "$SCORE" > ".submission"
echo -n "$SCORE$ISHA" | sha256sum | cut -d' ' -f1 | xxd -r -p >> ".submission"
HW_SUBMISSION_ZIP="${USER}_hw-submission.zip"
zip "$HW_SUBMISSION_ZIP" "iterative.c" ".submission" > /dev/null 2>&1
echo "Created zip file for homework submission: $HW_SUBMISSION_ZIP"
{ rm "$ITERATIVE_BENCH_FILE"; rm "$VECTORIZED_BENCH_FILE"; } > /dev/null 2>&1
trap - EXIT

