# hush-json — pure shell JSON interpreter
# Source this file: . ./lib/json.sh
# Depends on: lib/awk/json_engine.awk (awk state machine)

# ---- error handling ----
# hush has no trap ERR, no FUNCNAME, no BASH_LINENO.
# Best we can do: manual exit code checks + line-number reporting.
# Set _JSON_DEBUG=1 before sourcing to enable set -x tracing.

_JSON_ERROR=""   # last error message
_JSON_ELINE=""   # line number where last error occurred

# die <msg> [exit_code]
die() {
	_msg="$1" _code="${2:-1}"
	printf 'hush-json ERROR (line %s): %s\n' "${_JSON_ELINE:-?}" "$_msg" >&2
	exit "$_code"
}

# _json_trap <line_no> <msg> — record error context, return 1
_json_trap() {
	_JSON_ELINE="$1"
	_JSON_ERROR="$2"
	return 1
}

# ---- config ----

# Path to awk engine. Try in order:
#   1. _JSON_HOME override (set before sourcing)
#   2. <cwd>/hush-json/lib/...  (submodule in hush-bot)
#   3. <cwd>/lib/awk/...        (standalone hush-json repo)
_find_awk() {
	if [ -n "$_JSON_HOME" ] && [ -f "$_JSON_HOME/lib/awk/json_engine.awk" ]; then
		echo "$_JSON_HOME/lib/awk/json_engine.awk"; return
	fi
	for _d in "$(pwd)/hush-json" "$(pwd)"; do
		[ -f "$_d/lib/awk/json_engine.awk" ] && { echo "$_d/lib/awk/json_engine.awk"; return; }
	done
	echo ""
}
_JSON_AWK="$(_find_awk)"
if [ -z "$_JSON_AWK" ]; then
	echo "hush-json: cannot find json_engine.awk. Set _JSON_HOME before sourcing." >&2
	exit 1
fi

[ "${_JSON_DEBUG:-0}" = "1" ] && set -x

# ---- internal helpers ----

# Read JSON from arg or stdin
_json_input() {
	if [ -n "$1" ]; then
		printf '%s\n' "$1"
	else
		cat
	fi
}

# Call awk engine. Result on stdout. On failure sets _JSON_ERROR and returns 1.
_json_awk() {
	_mode="$1" _key="$2" _json="$3"
	_errf="/tmp/hj-err.$$"
	printf '%s\n' "$_json" | awk -v md="$_mode" -v k="$_key" -f "$_JSON_AWK" 2>"$_errf"
	_rc=$?
	if [ $_rc -ne 0 ]; then
		_JSON_ERROR="$(cat "$_errf")"
		rm -f "$_errf"
		return 1
	fi
	rm -f "$_errf"
	return 0
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
# Each returns the value on stdout, or returns 1 and sets _JSON_ERROR on failure.
# Usage: json_get <json> <key>   OR   echo <json> | json_get '' <key>

_json_parse() {
	_mode="$1" _json="$2" _key="$3"
	_outf="/tmp/hj-out.$$"
    # Call _json_awk directly (NOT in subshell) so _JSON_ERROR survives
	_json_awk "$_mode" "$_key" "$_json" >"$_outf"
	_rc=$?
	if [ $_rc -ne 0 ]; then
		_json_trap "$LINENO" "$_JSON_ERROR"
		rm -f "$_outf"
		return 1
	fi
	cat "$_outf"
	rm -f "$_outf"
	return 0
}

json_get() {
	_input="$(_json_input "$1")"
	if [ -n "$1" ] && [ -n "$2" ]; then
		_json_parse get "$_input" "$2" || { _ERROR="json.get: $_JSON_ERROR"; return 1; }
	elif [ -z "$1" ]; then
		_json_parse get "$_input" "$2" || { _ERROR="json.get: $_JSON_ERROR"; return 1; }
	else
		_json_parse get "$_input" "$1" || { _ERROR="json.get: $_JSON_ERROR"; return 1; }
	fi
}

json_type() {
	_input="$(_json_input "$1")"
	if [ -n "$1" ] && [ -n "$2" ]; then
		_json_parse type "$_input" "$2"
	elif [ -z "$1" ]; then
		_json_parse type "$_input" "$2"
	else
		_json_parse type "$_input" "$1"
	fi
}

json_keys() {
	_input="$(_json_input "$1")"
	_json_parse keys "$_input" ""
}

json_len() {
	_input="$(_json_input "$1")"
	if [ -n "$1" ] && [ -n "$2" ]; then
		_json_parse len "$_input" "$2"
	elif [ -z "$1" ]; then
		_json_parse len "$_input" "$2"
	else
		_json_parse len "$_input" "$1"
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

# json_arr_len <json_array>
# Returns length of JSON array (direct, no key lookup)
json_arr_len() {
	_input="$(_json_input "$1")"
	_json_parse alen "$_input" ""
}

# json_arr_at <json_array> <index>
# Returns element at index (0-based) from JSON array
json_arr_at() {
	_input="$(_json_input "$1")"
	_json_parse aget "$_input" "$2"
}

# ---- short aliases ----
hjg() { json_get "$@"; }
hjt() { json_type "$@"; }
hjk() { json_keys "$@"; }
hjl() { json_len "$@"; }
hje() { json_escape "$@"; }
hjo() { json_obj "$@"; }
hja() { json_arr "$@"; }
hjal() { json_arr_len "$@"; }
hjaa() { json_arr_at "$@"; }
