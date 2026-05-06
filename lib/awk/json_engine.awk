# hush-json awk engine — JSON value extractor
#
# IMPORTANT: All variable/parameter names are 1-3 chars.
# BusyBox awk (1.37) fails with "Unexpected token" if function
# signature lines are too long (~55+ chars total). Long names
# like extract_bracket / depth / in_str trigger this bug.
# Rule: every name ≤ 3 chars.
#
# Usage: awk -v md=get -v k="name" -f json_engine.awk < input.json
# Modes: md = get | type | keys | len

BEGIN {
    s = ""
    while ((getline l) > 0) s = s l
    gsub(/\r/, "", s)

    if (md == "keys") dk(s)
    else if (md == "len") dl(s, k)
    else if (md == "alen") al(s)
    else if (md == "aget") da(s, int(k))
    else if (md == "type") dt(s, k)
    else dg(s, k)
}

# ---- helpers ----

# skip whitespace from position p, return next non-ws position
function ws(s, p,    c) {
    while (p <= length(s)) {
        c = substr(s, p, 1)
        if (c != " " && c != "\t" && c != "\n" && c != "\r") break
        p++
    }
    return p
}

# extract JSON string starting at p (p points to opening ")
# handles: \" \\ (structural escapes)
# \n \t \r \b \f \/ \uXXXX are preserved as-is
#  because BusyBox awk cannot represent real control chars
# sets global ep = position after closing "
function xs(s, p,    c, c2, r, i) {
    r = ""; i = p + 1
    while (i <= length(s)) {
        c = substr(s, i, 1)
        if (c == "\\") {
            i++
            if (i > length(s)) break
            c2 = substr(s, i, 1)
            # Only resolve \" → " and \\ → \ for structural correctness
            if (c2 == "\"") r = r "\""
            else if (c2 == "\\") r = r "\\"
            else {
                # Preserve: \n \t \r \/ \uXXXX etc. as literal text
                r = r "\\" c2
            }
        } else if (c == "\"") break
        else r = r c
        i++
    }
    ep = i + 1
    return r
}

# extract balanced bracket pair [array] or {object}
# o=opening char, cl=closing char
# sets global ep = position after closing bracket
function xb(s, p, o, cl,    d, c, i, q, e) {
    i = p + 1; d = 1; q = 0; e = 0
    while (i <= length(s) && d > 0) {
        c = substr(s, i, 1)
        if (q) {
            if (e) e = 0
            else if (c == "\\") e = 1
            else if (c == "\"") q = 0
        } else {
            if (c == "\"") q = 1
            else if (c == o) d++
            else if (c == cl) d--
        }
        i++
    }
    ep = i
    return substr(s, p, i - p)
}

# extract number starting at p
# sets global ep = position after number
function xn(s, p,    i, c, r) {
    i = p; r = ""
    while (i <= length(s)) {
        c = substr(s, i, 1)
        if (c ~ /[0-9eE.+\-]/) { r = r c; i++ }
        else break
    }
    ep = i
    return r
}

# extract ANY JSON value at position p
# sets global ep AND vt (value type: string/number/boolean/null/array/object)
function xv(s, p,    c) {
    p = ws(s, p)
    c = substr(s, p, 1)

    if (c == "\"") { vt = "string";  return xs(s, p) }
    if (c == "[")  { vt = "array";   return xb(s, p, "[", "]") }
    if (c == "{")  { vt = "object";  return xb(s, p, "{", "}") }
    if (c == "t" && substr(s, p, 4) == "true")  { ep = p + 4; vt = "boolean"; return "true" }
    if (c == "f" && substr(s, p, 5) == "false") { ep = p + 5; vt = "boolean"; return "false" }
    if (c == "n" && substr(s, p, 4) == "null")  { ep = p + 4; vt = "null";   return "null" }
    if (c == "-" || (c >= "0" && c <= "9")) { vt = "number"; return xn(s, p) }

    vt = "unknown"; ep = p; return ""
}

# find key in top-level object, return position after ":" or 0
function fk(s, tg,    i, c, d, k) {
    if (substr(s, ws(s, 1), 1) != "{") return 0
    i = ws(s, 2); d = 1
    while (i <= length(s) && d > 0) {
        c = substr(s, i, 1)
        if (c == "\"") {
            k = xs(s, i); i = ep
            i = ws(s, i)
            if (substr(s, i, 1) == ":") {
                if (k == tg) return i + 1
                xv(s, i + 1); i = ep
            }
        } else {
            if (c == "{") d++
            else if (c == "}") d--
            i++
        }
    }
    return 0
}

# ---- mode handlers ----

function dg(s, k) {
    p = fk(s, k)
    if (p == 0) { print "hush-json: key '" k "' not found" > "/dev/stderr"; exit 1 }
    print xv(s, p)
}

function dt(s, k) {
    p = fk(s, k)
    if (p == 0) { print "hush-json: key '" k "' not found" > "/dev/stderr"; exit 1 }
    xv(s, p)
    print vt
}

function dk(s,    i, c, d, k, fi) {
    if (substr(s, ws(s, 1), 1) != "{") { print ""; exit 0 }
    i = ws(s, 2); d = 1; fi = 1
    while (i <= length(s) && d > 0) {
        c = substr(s, i, 1)
        if (c == "\"") {
            k = xs(s, i); i = ep
            i = ws(s, i)
            if (substr(s, i, 1) == ":") {
                if (!fi) printf " "; fi = 0
                printf "%s", k
            }
            xv(s, i + 1); i = ep
        } else {
            if (c == "{") d++
            else if (c == "}") d--
            i++
        }
    }
    print ""
}

function dl(s, k,    p, v, j, c, d) {
    p = fk(s, k)
    if (p == 0) { print "hush-json: key '" k "' not found" > "/dev/stderr"; exit 1 }
    v = xv(s, p)
    if (vt != "array") { print "hush-json: key '" k "' is not an array (type: " vt ")" > "/dev/stderr"; exit 1 }
    if (v == "[]" || v == "[ ]") { print 0; exit 0 }
    n = 1; d = 0
    j = ws(v, 2)
    while (j <= length(v)) {
        c = substr(v, j, 1)
        if (c == "\"") { xs(v, j); j = ep }
        else if (c == "[" || c == "{") { xb(v, j, c, (c == "[" ? "]" : "}")); j = ep }
        else if (c == "," && d == 0) { n++; j++ }
        else if (c == "]") break
        else j++
    }
    print n
}

# al: array length (direct — input is the array itself, not an object)
function al(s,    j, c, n) {
    if (substr(s, ws(s, 1), 1) != "[") {
        print "hush-json: not an array" > "/dev/stderr"; exit 1
    }
    s = substr(s, ws(s, 1))
    if (s == "[]" || s == "[ ]") { print 0; exit 0 }
    n = 1
    j = ws(s, 2)
    while (j <= length(s)) {
        c = substr(s, j, 1)
        if (c == "\"") { xs(s, j); j = ep }
        else if (c == "[" || c == "{") { xb(s, j, c, (c == "[" ? "]" : "}")); j = ep }
        else if (c == ",") { n++; j++ }
        else if (c == "]") break
        else j++
    }
    print n
}

# da: dump array element at index n (0-based) — direct array input
function da(s, n,    j, c, i, v) {
    if (substr(s, ws(s, 1), 1) != "[") {
        print "hush-json: not an array" > "/dev/stderr"; exit 1
    }
    i = 0
    j = ws(s, 2)
    c = substr(s, j, 1)
    if (c == "]") {
        print "hush-json: index " n " out of bounds (empty)" > "/dev/stderr"; exit 1
    }
    while (j <= length(s)) {
        j = ws(s, j)
        if (j > length(s)) break
        c = substr(s, j, 1)
        if (c == "]") break

        v = xv(s, j)
        if (i == n) { print v; exit 0 }
        i++
        j = ep
        j = ws(s, j)
        c = substr(s, j, 1)
        if (c == ",") j++
    }
    print "hush-json: index " n " out of bounds" > "/dev/stderr"; exit 1
}
