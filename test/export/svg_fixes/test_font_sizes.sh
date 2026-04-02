#!/bin/sh

# Thorough font size comparison test.
# For each test case, exports both PNG and SVG and compares canvas sizes.
# A mismatch means the SVG text metrics differ from the screen renderer.

JAR=../../jar/fidocadj.jar
fail=0
total=0
pass=0

check_size() {
    desc="$1"
    fcd="$2"
    res="$3"
    total=$((total + 1))

    java -jar $JAR -n -c r${res} png svg_fixes/_test_fs.png "$fcd" 2>/dev/null
    java -jar $JAR -n -c r${res} svg svg_fixes/_test_fs.svg "$fcd" 2>/dev/null

    # Get PNG dimensions
    png_w=$(file svg_fixes/_test_fs.png | grep -o '[0-9]* x [0-9]*' | cut -d' ' -f1)
    png_h=$(file svg_fixes/_test_fs.png | grep -o '[0-9]* x [0-9]*' | cut -d' ' -f3)

    # Get SVG dimensions
    svg_w=$(head -3 svg_fixes/_test_fs.svg | grep -o 'width="[0-9.]*"' | grep -o '[0-9.]*' | head -1)
    svg_h=$(head -3 svg_fixes/_test_fs.svg | grep -o 'height="[0-9.]*"' | grep -o '[0-9.]*' | head -1)

    # Compare (truncate SVG floats to int for comparison)
    svg_wi=$(echo "$svg_w" | cut -d. -f1)
    svg_hi=$(echo "$svg_h" | cut -d. -f1)

    if [ "$png_w" = "$svg_wi" ] && [ "$png_h" = "$svg_hi" ]; then
        pass=$((pass + 1))
        echo "  OK   $desc (${png_w}x${png_h})"
    else
        fail=1
        printf "  \033[1m\x1b[31mFAIL\033[0m $desc\n"
        printf "       PNG: ${png_w}x${png_h}  SVG: ${svg_w}x${svg_h}\n"
    fi
    rm -f svg_fixes/_test_fs.png svg_fixes/_test_fs.svg
}

echo ""
echo "Font Size Comparison Tests"
echo "--------------------------"
echo ""

# Test various sizex/sizey combinations
cat > svg_fixes/_fs1.fcd << 'EOF'
[FIDOCAD]
TY 10 10 4 3 0 0 0 * Hello World
EOF

cat > svg_fixes/_fs2.fcd << 'EOF'
[FIDOCAD]
TY 10 10 8 3 0 0 0 * Wide Text
EOF

cat > svg_fixes/_fs3.fcd << 'EOF'
[FIDOCAD]
TY 10 10 4 8 0 0 0 * Tall Text
EOF

cat > svg_fixes/_fs4.fcd << 'EOF'
[FIDOCAD]
TY 10 10 10 7 0 0 0 * Default Ratio
EOF

cat > svg_fixes/_fs5.fcd << 'EOF'
[FIDOCAD]
TY 10 10 3 2 0 0 0 * Small
EOF

cat > svg_fixes/_fs6.fcd << 'EOF'
[FIDOCAD]
TY 10 10 6 4 0 1 0 * Bold Text
EOF

cat > svg_fixes/_fs7.fcd << 'EOF'
[FIDOCAD]
TY 10 10 5 3 0 0 0 * X^2 + Y^2
EOF

cat > svg_fixes/_fs8.fcd << 'EOF'
[FIDOCAD]
TY 10 10 4 3 0 0 0 * Line One
TY 10 20 8 5 0 0 0 * Line Two Bigger
TY 10 35 3 2 0 0 0 * Line Three Small
EOF

echo "At r2:"
check_size "4x3 normal text r2" svg_fixes/_fs1.fcd 2
check_size "8x3 wide text r2" svg_fixes/_fs2.fcd 2
check_size "4x8 tall text r2" svg_fixes/_fs3.fcd 2
check_size "10x7 default ratio r2" svg_fixes/_fs4.fcd 2
check_size "3x2 small text r2" svg_fixes/_fs5.fcd 2
check_size "6x4 bold text r2" svg_fixes/_fs6.fcd 2
check_size "5x3 superscript r2" svg_fixes/_fs7.fcd 2
check_size "mixed sizes r2" svg_fixes/_fs8.fcd 2

echo ""
echo "At r3:"
check_size "4x3 normal text r3" svg_fixes/_fs1.fcd 3
check_size "8x3 wide text r3" svg_fixes/_fs2.fcd 3
check_size "4x8 tall text r3" svg_fixes/_fs3.fcd 3
check_size "10x7 default ratio r3" svg_fixes/_fs4.fcd 3
check_size "3x2 small text r3" svg_fixes/_fs5.fcd 3
check_size "6x4 bold text r3" svg_fixes/_fs6.fcd 3
check_size "5x3 superscript r3" svg_fixes/_fs7.fcd 3
check_size "mixed sizes r3" svg_fixes/_fs8.fcd 3

echo ""
echo "At r5:"
check_size "4x3 normal text r5" svg_fixes/_fs1.fcd 5
check_size "8x3 wide text r5" svg_fixes/_fs2.fcd 5
check_size "3x2 small text r5" svg_fixes/_fs5.fcd 5
check_size "5x3 superscript r5" svg_fixes/_fs7.fcd 5

echo ""
echo "At r10:"
check_size "4x3 normal text r10" svg_fixes/_fs1.fcd 10
check_size "3x2 small text r10" svg_fixes/_fs5.fcd 10

rm -f svg_fixes/_fs*.fcd
echo ""
echo "Results: $pass/$total passed"
if [ $fail -ne 0 ]; then
    printf "\033[1m\x1b[31mSome font size tests failed!\033[0m\n"
fi
exit $fail
