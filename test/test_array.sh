# Array tests

test_array_basic() {
    assert_eq "$(json_get '{"arr":[1,2,3]}' arr)" "[1,2,3]" "basic array"
}

test_array_strings() {
    assert_eq "$(json_get '{"arr":["a","b"]}' arr)" '["a","b"]' "string array"
}

test_array_empty() {
    assert_eq "$(json_get '{"arr":[]}' arr)" "[]" "empty array"
}

test_array_nested_objects() {
    assert_eq "$(json_get '{"arr":[{"x":1}]}' arr)" '[{"x":1}]' "array of objects"
}

test_array_len() {
    assert_eq "$(json_len '{"arr":[1,2,3,4,5]}' arr)" "5" "array length"
    assert_eq "$(json_len '{"arr":[]}' arr)" "0" "empty array length"
    assert_eq "$(json_len '{"arr":[42]}' arr)" "1" "single element length"
}

test_array_type() {
    assert_eq "$(json_type '{"x":[1]}' x)" "array" "type of array"
}

test_array_basic
test_array_strings
test_array_empty
test_array_nested_objects
test_array_len
test_array_type
