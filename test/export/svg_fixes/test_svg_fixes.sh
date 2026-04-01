#!/bin/sh

# Test suite for SVG export fixes
# Each test exports a minimal FCD file to SVG and checks for
# specific properties in the output.

JAR=../../jar/fidocadj.jar
test_fail=0
test_count=0
pass_count=0

assert_contains() {
    test_count=$((test_count + 1))
    desc="$1"
    file="$2"
    pattern="$3"
    if grep -q "$pattern" "$file"; then
        pass_count=$((pass_count + 1))
        echo "  OK   $desc"
    else
        test_fail=1
        printf "  \033[1m\x1b[31mFAIL\033[0m $desc\n"
        printf "       Expected pattern: $pattern\n"
    fi
}

assert_not_contains() {
    test_count=$((test_count + 1))
    desc="$1"
    file="$2"
    pattern="$3"
    if grep -q "$pattern" "$file"; then
        test_fail=1
        printf "  \033[1m\x1b[31mFAIL\033[0m $desc\n"
        printf "       Unexpected pattern found: $pattern\n"
    else
        pass_count=$((pass_count + 1))
        echo "  OK   $desc"
    fi
}

echo ""
echo "SVG Export Fixes - Test Suite"
echo "-----------------------------"
echo ""

# --- Fix 1: font-weight typo ---
echo "Fix 1: font-weight attribute spelling"
java -jar $JAR -n -c r2 svg svg_fixes/out_bold.svg \
    svg_fixes/test_bold_text.fcd 2>/dev/null
assert_contains \
    "font-weight is spelled correctly" \
    svg_fixes/out_bold.svg \
    'font-weight='
assert_not_contains \
    "font-weigth typo is absent" \
    svg_fixes/out_bold.svg \
    'font-weigth='

echo ""
echo "Results: $pass_count/$test_count passed"
if test $test_fail != 0; then
    printf "\033[1m\x1b[31mSome tests failed!\033[0m\n"
fi
exit $test_fail
