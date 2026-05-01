# String value tests
# Note: BusyBox awk cannot represent real \n \t \r chars,
# so only \" and \\ are structurally resolved.
# Other escapes (\n \t \r \/ \u) are preserved as-is.

test_string_basic() {
    assert_eq "$(json_get '{"k":"hello"}' k)" "hello" "basic string"
    assert_eq "$(json_get '{"k":""}' k)" "" "empty string"
}

test_string_escape_quote() {
    # \" → "  (structurally resolved)
    assert_eq "$(json_get '{"k":"he \"said\" hi"}' k)" 'he "said" hi' "escaped quote"
    # JSON: {"k":"a\"b"}  → value: a"b
    assert_eq "$(json_get '{"k":"a\"b"}' k)" 'a"b' "single escaped quote"
}

test_string_escape_backslash() {
    # JSON: {"k":"a\\b"}  → value: a\b
    assert_eq "$(json_get '{"k":"a\\b"}' k)" 'a\b' "escaped backslash"
}

test_string_escape_n() {
    # \n preserved as \n
    assert_eq "$(json_get '{"k":"a\\nb"}' k)" 'a\nb' "escaped n preserved"
}

test_string_escape_t() {
    # \t preserved as \t
    assert_eq "$(json_get '{"k":"a\\tb"}' k)" 'a\tb' "escaped t preserved"
}

test_string_escape_slash() {
    # \/ preserved as \/
    assert_eq "$(json_get '{"k":"a\\/b"}' k)" 'a\/b' "escaped slash preserved"
}

test_string_unicode() {
    # \uXXXX preserved
    assert_eq "$(json_get '{"k":"\\u4f60"}' k)" '\u4f60' "unicode pass-through"
}

test_string_multiple_keys() {
    assert_eq "$(json_get '{"a":"1","b":"2","c":"3"}' b)" "2" "get middle key"
    assert_eq "$(json_get '{"first":"one","second":"two"}' first)" "one" "get first key"
}

test_string_basic
test_string_escape_quote
test_string_escape_backslash
test_string_escape_n
test_string_escape_t
test_string_escape_slash
test_string_unicode
test_string_multiple_keys
