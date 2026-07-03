#!/usr/bin/env python3
"""Structural sanity checker for DXF files produced by ExportDXF.java.

This is a manual/developer aid, not part of the automated diff-based
regression suite (test_export.sh / check.sh): it does not know whether
the geometry is *correct*, only whether the file is well-formed DXF
(balanced sections/tables, sane vertex/entity pairing, ends with EOF).
Real visual/geometric validation still requires opening the file in an
actual CAD viewer.

Usage: python3 validate_dxf.py <file.dxf>
"""
import sys


def validate(path):
    with open(path, 'r', encoding='utf-8', errors='strict') as f:
        lines = [l.rstrip('\n').rstrip('\r') for l in f.readlines()]

    errors = []

    if len(lines) % 2 != 0:
        errors.append(
            "Odd number of lines: not a valid group-code/value stream")

    pairs = []
    for i in range(0, len(lines) - 1, 2):
        code_line = lines[i]
        value = lines[i + 1]
        try:
            code = int(code_line.strip())
        except ValueError:
            errors.append(
                f"Line {i+1}: group code '{code_line}' is not an integer")
            continue
        pairs.append((code, value))

    n = len(pairs)
    known_entities = {"LINE", "CIRCLE", "POLYLINE", "VERTEX", "SEQEND",
                       "TEXT", "SOLID", "POINT"}

    section_depth = 0
    table_depth = 0
    polyline_open = False
    entity_section = False

    for i in range(n):
        code, val = pairs[i]
        if code != 0:
            continue
        if val == "SECTION":
            section_depth += 1
            if i + 1 < n and pairs[i + 1][0] == 2:
                entity_section = (pairs[i + 1][1] == "ENTITIES")
        elif val == "ENDSEC":
            section_depth -= 1
            entity_section = False
            if section_depth < 0:
                errors.append(f"Pair {i}: ENDSEC with no matching SECTION")
        elif val == "TABLE":
            table_depth += 1
        elif val == "ENDTAB":
            table_depth -= 1
            if table_depth < 0:
                errors.append(f"Pair {i}: ENDTAB with no matching TABLE")
        elif val == "POLYLINE":
            if polyline_open:
                errors.append(f"Pair {i}: nested POLYLINE without SEQEND")
            polyline_open = True
        elif val == "SEQEND":
            if not polyline_open:
                errors.append(f"Pair {i}: SEQEND with no matching POLYLINE")
            polyline_open = False
        elif val == "VERTEX":
            if not polyline_open:
                errors.append(
                    f"Pair {i}: VERTEX outside of a POLYLINE/SEQEND block")
        elif (entity_section and val not in known_entities
                and val not in ("SECTION", "ENDSEC")):
            errors.append(
                f"Pair {i}: unexpected entity type '{val}' in "
                "ENTITIES section")

    # Table record-count sanity: "0 TABLE / 2 <name> / 70 <count>" must
    # match the number of "0 <name>" records before the matching ENDTAB.
    i = 0
    while i < n - 2:
        if (pairs[i] == (0, "TABLE") and pairs[i + 1][0] == 2
                and pairs[i + 2][0] == 70):
            name = pairs[i + 1][1]
            declared = int(pairs[i + 2][1])
            j = i + 3
            actual = 0
            depth = 1
            while j < n and depth > 0:
                if pairs[j] == (0, "ENDTAB"):
                    depth -= 1
                elif pairs[j][0] == 0 and pairs[j][1] == name:
                    actual += 1
                j += 1
            if declared != actual:
                errors.append(
                    f"Table {name}: header count {declared} != actual "
                    f"records {actual}")
        i += 1

    if section_depth != 0:
        errors.append(f"Unbalanced SECTION/ENDSEC: depth={section_depth}")
    if table_depth != 0:
        errors.append(f"Unbalanced TABLE/ENDTAB: depth={table_depth}")
    if polyline_open:
        errors.append("File ends with an unclosed POLYLINE (no SEQEND)")

    if n < 2 or pairs[-1] != (0, "EOF"):
        errors.append(
            f"Last group pair is {pairs[-1] if n else None}, "
            "expected (0, 'EOF')")
    if n < 2 or pairs[-2] != (0, "ENDSEC"):
        errors.append(
            f"Second-to-last group pair is {pairs[-2] if n>=2 else None}, "
            "expected (0, 'ENDSEC')")

    return errors, n


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 validate_dxf.py <file.dxf>")
        sys.exit(2)
    target = sys.argv[1]
    found_errors, pair_count = validate(target)
    print(f"Checked {pair_count} group-code/value pairs from {target}")
    if found_errors:
        print(f"FOUND {len(found_errors)} STRUCTURAL ISSUE(S):")
        for e in found_errors:
            print("  -", e)
        sys.exit(1)
    print("No structural issues found.")
    sys.exit(0)
