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

# --- Fix 2: stroke-linejoin and stroke-linecap ---
echo "Fix 2: round line joins and caps"
java -jar $JAR -n -c r2 svg svg_fixes/out_lines.svg \
    svg_fixes/test_line_joins.fcd 2>/dev/null
assert_contains \
    "lines have stroke-linejoin:round" \
    svg_fixes/out_lines.svg \
    'stroke-linejoin:round'
assert_contains \
    "lines have stroke-linecap:round" \
    svg_fixes/out_lines.svg \
    'stroke-linecap:round'

# --- Fix 3: fill-rule nonzero ---
echo "Fix 3: fill-rule nonzero"
java -jar $JAR -n -c r2 svg svg_fixes/out_fill.svg \
    svg_fixes/test_fill_rule.fcd 2>/dev/null
assert_contains \
    "fill-rule is nonzero" \
    svg_fixes/out_fill.svg \
    'fill-rule: nonzero'
assert_not_contains \
    "fill-rule evenodd is absent" \
    svg_fixes/out_fill.svg \
    'fill-rule: evenodd'

# --- Fix 4: layer opacity ---
echo "Fix 4: layer opacity"
java -jar $JAR -n -c r2 svg svg_fixes/out_opacity.svg \
    svg_fixes/test_opacity.fcd 2>/dev/null
assert_contains \
    "opacity attribute present for semi-transparent layer" \
    svg_fixes/out_opacity.svg \
    'opacity="0.3"'

# --- Fix 5: minimum stroke width ---
echo "Fix 5: minimum stroke width"
java -jar $JAR -n -c r2 svg svg_fixes/out_min_stroke.svg \
    svg_fixes/test_min_stroke.fcd 2>/dev/null
assert_not_contains \
    "no zero-width strokes in PCB lines" \
    svg_fixes/out_min_stroke.svg \
    'stroke-width:0[^.]'
assert_not_contains \
    "no zero-width strokes in general" \
    svg_fixes/out_min_stroke.svg \
    'stroke-width:0"'

echo ""
echo "Results: $pass_count/$test_count passed"
if test $test_fail != 0; then
    printf "\033[1m\x1b[31mSome tests failed!\033[0m\n"
fi
exit $test_fail
