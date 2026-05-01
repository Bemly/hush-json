# Boolean and null value tests

test_bool_true() {
    assert_eq "$(json_get '{"ok":true}' ok)" "true" "boolean true"
}

test_bool_false() {
    assert_eq "$(json_get '{"ok":false}' ok)" "false" "boolean false"
}

test_null() {
    assert_eq "$(json_get '{"x":null}' x)" "null" "null value"
}

test_bool_type() {
    assert_eq "$(json_type '{"x":true}' x)" "boolean" "type of true"
    assert_eq "$(json_type '{"x":false}' x)" "boolean" "type of false"
}

test_null_type() {
    assert_eq "$(json_type '{"x":null}' x)" "null" "type of null"
}

test_bool_true
test_bool_false
test_null
test_bool_type
test_null_type
