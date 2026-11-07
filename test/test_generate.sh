# JSON generation tests

test_escape_basic() {
    assert_eq "$(json_escape 'hello')" '"hello"' "escape plain text"
}

test_escape_quote() {
    assert_eq "$(json_escape 'say "hi"')" '"say \"hi\""' "escape internal quote"
}

test_escape_backslash() {
    assert_eq "$(json_escape 'a\b')" '"a\\b"' "escape backslash"
}

test_obj_basic() {
    # 1 and 2 detected as numbers → raw (no quotes)
    assert_eq "$(json_obj 'a' '1' 'b' '2')" '{"a":1,"b":2}' "obj numbers raw"
}

test_obj_mixed_types() {
    result="$(json_obj 's' 'hi' 'n' 42 'ok' true 'nil' null)"
    # Check that true and null are NOT quoted
    case "$result" in
        *':true'*) ;; *) printf 'FAIL: obj true not raw\n  got: %s\n' "$result"; return 1 ;; esac
    case "$result" in
        *':null'*) ;; *) printf 'FAIL: obj null not raw\n  got: %s\n' "$result"; return 1 ;; esac
    case "$result" in
        *':42'*) ;; *) printf 'FAIL: obj number not raw\n  got: %s\n' "$result"; return 1 ;; esac
    case "$result" in
        *'"hi"'*) ;; *) printf 'FAIL: obj string not quoted\n  got: %s\n' "$result"; return 1 ;; esac
}

test_obj_single_pair() {
    assert_eq "$(json_obj 'key' 'val')" '{"key":"val"}' "obj single pair"
}

test_obj_empty() {
    # shell passes no args -> json_obj receives nothing
    assert_eq "$(json_obj)" "{}" "obj no args"
}

test_arr_basic() {
    assert_eq "$(json_arr 'a' 'b' 'c')" '["a","b","c"]' "arr basic"
}

test_arr_mixed() {
    result="$(json_arr 'hello' 42 true null)"
    case "$result" in *':') ;; *) ;; esac  # skip
    # Verify it has 4 items
    assert_eq "$(printf '%s' "$result" | grep -o ',' | wc -l)" "3" "arr mixed 4 items comma count"
}

test_arr_nested() {
    inner="$(json_obj 'x' 1)"
    result="$(json_arr "$inner" "$inner")"
    assert_eq "$result" '[{"x":1},{"x":1}]' "arr nested objects"
}

test_escape_control_chars() {
    # A bare LF/TAB/CR in the body produced invalid JSON and the server
    # answered 500 (QQ 50015001). They must be emitted as two-char escapes.
    result="$(json_escape "$(printf 'l1\nl2')")"
    assert_eq "$result" '"l1\nl2"' "escape real LF"
    result="$(json_escape "$(printf 'a\tb\rc')")"
    assert_eq "$result" '"a\tb\rc"' "escape real TAB and CR"
    result="$(json_escape "$(printf 'a\010b\014c')")"
    assert_eq "$result" '"a\bb\fc"' "escape real BS and FF"
}

test_obj_multiline() {
    result="$(json_obj content "$(printf '第一行\n第二行')")"
    assert_eq "$result" '{"content":"第一行\n第二行"}' "obj multiline value"
}

test_escape_basic
test_escape_quote
test_escape_backslash
test_escape_control_chars
test_obj_basic
test_obj_mixed_types
test_obj_single_pair
test_obj_multiline
test_obj_empty
test_arr_basic
test_arr_mixed
test_arr_nested
