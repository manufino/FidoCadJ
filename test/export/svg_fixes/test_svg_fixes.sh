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

# Fix 3 was reverted: fill-rule should remain evenodd (matching Java2D's
# WIND_EVEN_ODD used in ShapeSwing.java and ShapeNull.java)

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

# --- Fix 6: font CSS fallbacks ---
echo "Fix 6: font CSS fallbacks"
java -jar $JAR -n -c r2 svg svg_fixes/out_font_fallback.svg \
    svg_fixes/test_font_fallback.fcd 2>/dev/null
assert_contains \
    "Courier New has monospace fallback" \
    svg_fixes/out_font_fallback.svg \
    'font-family="Courier New, monospace"'

# --- Fix 7: font size based on sizex, with yscale ---
echo "Fix 7: font size and vertical scaling"
java -jar $JAR -n -c r2 svg svg_fixes/out_font_size.svg \
    svg_fixes/test_font_size.fcd 2>/dev/null
assert_not_contains \
    "font size is not based on sizey" \
    svg_fixes/out_font_size.svg \
    'font-size="14.0"'
assert_not_contains \
    "transform uses yscale, not old xscale approach" \
    svg_fixes/out_font_size.svg \
    'scale(1.7'

# --- Fix 8: text baseline uses font ascent ---
echo "Fix 8: text baseline uses font ascent"
java -jar $JAR -n -c r2 svg svg_fixes/out_baseline.svg \
    svg_fixes/test_baseline.fcd 2>/dev/null
# With sizex=10 at r2, font-size ~ 24.5. The old code sets y=font-size.
# The fix uses ascent which is smaller. y should NOT equal font-size.
assert_not_contains \
    "text y is not equal to font-size (uses ascent)" \
    svg_fixes/out_baseline.svg \
    'y="24.5"'

# --- Fix 9: filled open curves exported as polygons ---
echo "Fix 9: filled open curves as polygons"
java -jar $JAR -n -c r2 svg svg_fixes/out_filled_curve.svg \
    svg_fixes/test_filled_curve.fcd 2>/dev/null
assert_contains \
    "filled curve produces a polygon element" \
    svg_fixes/out_filled_curve.svg \
    '<polygon'
assert_contains \
    "filled curve has fill color" \
    svg_fixes/out_filled_curve.svg \
    'fill="#'

# --- Fix 10: text size rounding ---
echo "Fix 10: text size rounding"
java -jar $JAR -n -c r3 svg svg_fixes/out_size_rounding.svg \
    svg_fixes/test_size_rounding.fcd 2>/dev/null
assert_contains \
    "small text produces valid font-size" \
    svg_fixes/out_size_rounding.svg \
    'font-size="[0-9]'

# --- Fix 11: text mirror/orientation matching draw() ---
echo "Fix 11: text mirror/orientation in export"
java -jar $JAR -n -c r2 svg svg_fixes/out_macro_mirror.svg \
    svg_fixes/test_macro_mirror.fcd 2>/dev/null
# Style 4 = TEXT_MIRRORED. The export should pass the combined
# mirror flag (text mirror XOR coord mirror) like draw() does.
assert_contains \
    "mirrored text (style 4) has scale(-1" \
    svg_fixes/out_macro_mirror.svg \
    'scale(-1'

# --- Fix 12: preserve whitespace in text ---
echo "Fix 12: preserve whitespace in text"
java -jar $JAR -n -c r2 svg svg_fixes/out_whitespace.svg \
    svg_fixes/test_whitespace.fcd 2>/dev/null
assert_contains \
    "text element has xml:space=preserve" \
    svg_fixes/out_whitespace.svg \
    'xml:space="preserve"'

echo ""
echo "Results: $pass_count/$test_count passed"
if test $test_fail != 0; then
    printf "\033[1m\x1b[31mSome tests failed!\033[0m\n"
fi
exit $test_fail
