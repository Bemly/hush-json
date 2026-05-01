#!/bin/sh
# hush-json test runner
# Run inside busybox container:
#   docker run --rm -v $(pwd):/test busybox:musl sh /test/test/run.sh

cd "$(dirname "$0")/.." || exit 1
. ./lib/json.sh

PASS=0
FAIL=0

assert_eq() {
    _got="$1" _want="$2" _msg="$3"
    if [ "$_got" = "$_want" ]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        printf 'FAIL: %s\n' "$_msg"
        printf '  want: %s\n' "$_want"
        printf '  got:  %s\n' "$_got"
    fi
}

assert_ok() {
    _code=$?
    _msg="$1"
    if [ $_code -eq 0 ]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        printf 'FAIL: %s (exit=%d)\n' "$_msg" $_code
    fi
}

# ---- tests ----

# source test files
for _f in test/test_*.sh; do
    . "./$_f"
done

# ---- summary ----
printf '\n%s passed, %s failed, %s total\n' "$PASS" "$FAIL" $((PASS + FAIL))
[ "$FAIL" -eq 0 ] || exit 1
