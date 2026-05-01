# Number value tests

test_number_int() {
    assert_eq "$(json_get '{"n":42}' n)" "42" "positive int"
    assert_eq "$(json_get '{"n":0}' n)" "0" "zero"
    assert_eq "$(json_get '{"n":999999}' n)" "999999" "large int"
}

test_number_negative() {
    assert_eq "$(json_get '{"n":-1}' n)" "-1" "negative int"
    assert_eq "$(json_get '{"n":-3.14}' n)" "-3.14" "negative float"
}

test_number_float() {
    assert_eq "$(json_get '{"n":3.14}' n)" "3.14" "float"
    assert_eq "$(json_get '{"n":0.5}' n)" "0.5" "fraction"
}

test_number_scientific() {
    assert_eq "$(json_get '{"n":1e10}' n)" "1e10" "scientific"
    assert_eq "$(json_get '{"n":1.5e-3}' n)" "1.5e-3" "scientific negative exp"
}

test_number_multiple_in_object() {
    assert_eq "$(json_get '{"a":1,"b":2.5,"c":-3}' b)" "2.5" "float among ints"
}

test_number_int
test_number_negative
test_number_float
test_number_scientific
test_number_multiple_in_object
