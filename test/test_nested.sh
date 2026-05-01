# Nested object tests

test_nested_get_object() {
    assert_eq "$(json_get '{"outer":{"inner":"val"}}' outer)" '{"inner":"val"}' "get nested object"
}

test_nested_with_spaces() {
    # awk engine preserves original JSON whitespace in nested values
    assert_eq "$(json_get '{ "a" : { "b" : 1 } }' a)" '{ "b" : 1 }' "nested with spaces"
}

test_deeply_nested() {
    result="$(json_get '{"a":{"b":{"c":{"d":"deep"}}}}' a)"
    # Should return the entire nested value (no multi-level path in v1)
    case "$result" in *'"d":"deep"'*) ;; *)
        printf 'FAIL: deeply nested\n  want contains: "d":"deep"\n  got: %s\n' "$result"
        ;; esac
}

test_nested_type() {
    assert_eq "$(json_type '{"x":{"a":1}}' x)" "object" "type of nested object"
}

test_empty_object() {
    assert_eq "$(json_get '{"x":{}}' x)" "{}" "empty nested object"
}

test_keys_from_nested() {
    # keys only lists top-level keys
    assert_eq "$(json_keys '{"a":{"x":1},"b":2}')" "a b" "keys include nested key names"
}

test_nested_get_object
test_nested_with_spaces
test_deeply_nested
test_nested_type
test_empty_object
test_keys_from_nested
