# Roundtrip: parse then re-generate

test_roundtrip_string() {
    orig='{"msg":"hello"}'
    val="$(json_get "$orig" msg)"
    gen="$(json_obj 'msg' "$val")"
    assert_eq "$gen" "$orig" "roundtrip string"
}

test_roundtrip_number() {
    orig='{"count":42}'
    val="$(json_get "$orig" count)"
    gen="$(json_obj 'count' "$val")"
    assert_eq "$gen" "$orig" "roundtrip number"
}

test_roundtrip_bool() {
    orig='{"ok":true}'
    val="$(json_get "$orig" ok)"
    gen="$(json_obj 'ok' "$val")"
    assert_eq "$gen" "$orig" "roundtrip boolean"
}

test_roundtrip_multiple() {
    a="$(json_get '{"x":"hello","y":99}' x)"
    b="$(json_get '{"x":"hello","y":99}' y)"
    gen="$(json_obj 'x' "$a" 'y' "$b")"
    assert_eq "$gen" '{"x":"hello","y":99}' "roundtrip multiple keys"
}

test_roundtrip_nested_array() {
    # Extract array, embed in new object
    arr="$(json_get '{"items":[1,2,3]}' items)"
    gen="$(json_obj 'data' "$arr")"
    assert_eq "$gen" '{"data":[1,2,3]}' "roundtrip nested array"
}

test_roundtrip_string
test_roundtrip_number
test_roundtrip_bool
test_roundtrip_multiple
test_roundtrip_nested_array
