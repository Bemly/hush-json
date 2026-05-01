# hush-json

Pure shell JSON interpreter for BusyBox environments. Zero dependencies beyond BusyBox awk + sed. Parse and generate JSON from hush scripts.

## Quick start

```sh
. ./lib/json.sh

# Parse
json_get '{"name":"bemly"}' name        # → bemly
json_type '{"x":123}' x                  # → number
json_keys '{"a":1,"b":2}'               # → a b
json_len '{"arr":[1,2,3]}' arr          # → 3

# Generate
json_escape 'he said "hi"'              # → "he said \"hi\""
json_obj "msg" "hi" "count" 42          # → {"msg":"hi","count":42}
json_arr "a" "b" "c"                    # → ["a","b","c"]

# Nested
inner=$(json_obj "chat_id" 123 "text" "hello")
json_obj "method" "send" "body" "$inner"
# → {"method":"send","body":{"chat_id":123,"text":"hello"}}
```

## API

### Parse (Read)

| Function | Alias | Description |
|----------|-------|-------------|
| `json_get <json> <key>` | `hjg` | Extract value by key |
| `json_type <json> <key>` | `hjt` | Get value type |
| `json_keys <json>` | `hjk` | List top-level keys |
| `json_len <json> <key>` | `hjl` | Array length |

All parse functions accept JSON as first argument or via stdin:

```sh
echo '{"key":"val"}' | json_get '' key
curl -s https://api.example.com/data | json_get '' items
```

Types returned by `json_type`: `string`, `number`, `boolean`, `null`, `array`, `object`.

### Generate (Write)

| Function | Alias | Description |
|----------|-------|-------------|
| `json_escape <str>` | `hje` | Escape and quote a string |
| `json_obj <k1> <v1> ...` | `hjo` | Build a JSON object |
| `json_arr <v1> <v2> ...` | `hja` | Build a JSON array |

`json_obj` and `json_arr` auto-detect value types:
- `true` / `false` / `null` → raw (no quotes)
- Numbers (`42`, `-3.14`) → raw
- Values starting with `{` or `[` → raw (nested JSON)
- Everything else → escaped and quoted

### Error handling

Parse functions return exit code 1 on failure and set `_JSON_ERROR`:

```sh
json_get "$response" key || {
    echo "Parse failed: $_JSON_ERROR" >&2
    exit 1
}
```

`die()` prints the error with line number and exits:

```sh
json_get "$resp" token || die "missing token"
# → hush-json ERROR (line 23): missing token
```

Enable execution tracing with `_JSON_DEBUG=1`:

```sh
_JSON_DEBUG=1 . ./lib/json.sh
```

### Path override

Set `_JSON_HOME` before sourcing if installed outside `$PWD/lib/`:

```sh
_JSON_HOME=/opt/hush-json . /opt/hush-json/lib/json.sh
```

## hush error handling notes

hush (BusyBox shell) has no `trap ERR`, no `FUNCNAME`, no `BASH_LINENO`. What we do instead:
- **`die()`** — manual error exit with `$LINENO` for location
- **`_JSON_ERROR`** — global variable holds the last error message
- **`_JSON_DEBUG=1`** — enables `set -x` for tracing
- Parse functions return non-zero on failure — always check `$?`

## Escape handling

Only structural escapes are resolved:
- `\"` → `"` and `\\` → `\` (required for JSON structure)
- `\n` `\t` `\r` `\uXXXX` etc. are preserved as literal text

This is because BusyBox awk cannot represent real control characters (`"\n"` is literal `\n`). Most shell use cases want the literal escapes anyway.

## Testing

```sh
docker run --rm -v $(pwd):/test busybox:musl sh /test/test/run.sh
```

## License

MIT
