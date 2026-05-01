# hush-json — pure shell JSON interpreter
# Source this file: . ./lib/json.sh
# Depends on: lib/awk/json_engine.awk (awk state machine)

# Path to awk engine.
# Default: <cwd>/lib/awk/json_engine.awk. Override via _JSON_HOME.
if [ -n "$_JSON_HOME" ]; then
    _JSON_AWK="$_JSON_HOME/lib/awk/json_engine.awk"
else
    _JSON_AWK="$(pwd)/lib/awk/json_engine.awk"
fi

# ---- internal helpers ----

# Read JSON from arg or stdin
_json_input() {
    if [ -n "$1" ]; then
        printf '%s\n' "$1"
    else
        cat
    fi
}

# Call awk engine with given mode and key
_json_awk() {
    _mode="$1" _key="$2" _json="$3"
    printf '%s\n' "$_json" | awk -v md="$_mode" -v k="$_key" -f "$_JSON_AWK"
}

# Detect JSON value type for generation
# Returns: string | number | boolean | null | nested
_json_val_type() {
    _v="$1"
    # true / false / null
    case "$_v" in true|false|null) echo "raw"; return ;; esac

    # number (int, float, negative, scientific)
    case "$_v" in
        ''|*[!0-9eE.+\-]*) ;;
        *)
            _t="$(printf '%s' "$_v" | sed 's/[0-9]//g;s/e//g;s/E//g;s/\.//g;s/^-//g')"
            [ -z "$_t" ] && { echo "raw"; return; }
            ;;
    esac

    # nested JSON (object or array)
    _f="$(printf '%s' "$_v" | sed 's/^[[:space:]]*//;s/\(.\).*/\1/')"
    case "$_f" in '{'|'[') echo "nested"; return ;; esac

    echo "string"
}

# ---- parse API ----

# json_get <json> <key>    or   echo <json> | json_get '' <key>
json_get() {
    _input="$(_json_input "$1")"
    if [ -n "$1" ] && [ -n "$2" ]; then
        _json_awk get "$2" "$_input"
    elif [ -z "$1" ]; then
        _json_awk get "$2" "$_input"
    else
        _json_awk get "$1" "$_input"
    fi
}

# json_type <json> <key>
json_type() {
    _input="$(_json_input "$1")"
    if [ -n "$1" ] && [ -n "$2" ]; then
        _json_awk type "$2" "$_input"
    elif [ -z "$1" ]; then
        _json_awk type "$2" "$_input"
    else
        _json_awk type "$1" "$_input"
    fi
}

# json_keys <json>
json_keys() {
    _input="$(_json_input "$1")"
    _json_awk keys "" "$_input"
}

# json_len <json> <key>
json_len() {
    _input="$(_json_input "$1")"
    if [ -n "$1" ] && [ -n "$2" ]; then
        _json_awk len "$2" "$_input"
    elif [ -z "$1" ]; then
        _json_awk len "$2" "$_input"
    else
        _json_awk len "$1" "$_input"
    fi
}

# ---- generate API ----

# json_escape <string> — escape for JSON, wrap in double quotes
json_escape() {
    _s="$1"
    # Must escape \ first, then "
    _s="$(printf '%s' "$_s" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '"%s"' "$_s"
}

# json_obj <key1> <val1> [key2 val2 ...] — build JSON object
json_obj() {
    _out="{"
    _first=1
    while [ $# -gt 0 ]; do
        _k="$1"; _v="$2"; shift 2
        [ $_first -eq 0 ] && _out="$_out,"
        _first=0
        # Key always gets quoted
        _out="$_out$(json_escape "$_k")"
        _out="$_out:"
        # Value: detect type
        _t="$(_json_val_type "$_v")"
        case "$_t" in
            raw)    _out="$_out$_v" ;;
            nested) _out="$_out$_v" ;;
            *)      _out="$_out$(json_escape "$_v")" ;;
        esac
    done
    _out="$_out}"
    printf '%s' "$_out"
}

# json_arr <item1> [item2 ...] — build JSON array
json_arr() {
    _out="["
    _first=1
    for _v in "$@"; do
        [ $_first -eq 0 ] && _out="$_out,"
        _first=0
        _t="$(_json_val_type "$_v")"
        case "$_t" in
            raw)    _out="$_out$_v" ;;
            nested) _out="$_out$_v" ;;
            *)      _out="$_out$(json_escape "$_v")" ;;
        esac
    done
    _out="$_out]"
    printf '%s' "$_out"
}

# ---- short aliases ----
hjg() { json_get "$@"; }
hjt() { json_type "$@"; }
hjk() { json_keys "$@"; }
hjl() { json_len "$@"; }
hje() { json_escape "$@"; }
hjo() { json_obj "$@"; }
hja() { json_arr "$@"; }
