# llama.cpp - local OpenAI-compatible server

Everything is driven by two files:

- `ai/setup-ai-llamacpp.conf` - the only file you normally edit (model catalog + knobs)
- `ai/setup-ai-opencode.conf` - the opencode provider, **generated**, do not hand-edit

Runtime artifacts land in `~/.config/llamacpp/` (`llamacpp.env`, `models.ini`) and
are served by `configs-single/llamacpp.service`, a systemd **user** unit.

```sh
bash setup-ai -ill        # build + install llama.cpp (once)
bash setup-ai -sll -soc   # pick model + memory profile, wire it into opencode
```

The server is API-only (no web UI) on `http://127.0.0.1:8080/v1`.

---

## Where the RAM goes

Inference memory is four things, and only two of them are yours to choose:

```
weights + KV cache + compute buffers + everything else on the box
```

|              | size                                                  | changes with                               |
| ------------ | ----------------------------------------------------- | ------------------------------------------ |
| **weights**  | the GGUF file size                                    | the quantisation you pick - fixed per file |
| **KV cache** | `ctx × layers × kv_heads × head_dim × 2 × bytes/elem` | context window and KV type                 |
| **compute**  | ~1 GiB (`LLAMACPP_COMPUTE_RESERVE_MIB`)               | batch sizes                                |

The weights are a fixed cost once you choose a quant. The KV cache is the only
part that scales with your conversation history - **doubling `ctx` doubles it**.
So the real decision is: _after the weights, how much RAM is left for history?_

KV cache bytes per element, as a share of f16 (from the ggml block sizes):

| KV type | bytes/elem | vs f16 | use when                                             |
| ------- | ---------- | ------ | ---------------------------------------------------- |
| `f16`   | 2.000      | 100%   | you have RAM to spare, want zero loss                |
| `q8_0`  | 1.063      | 53%    | **default** - half the RAM, effectively lossless     |
| `q5_1`  | 0.750      | 38%    | big box, need a very long window                     |
| `q4_0`  | 0.625      | 31%    | only when the extra context is worth the recall risk |

`setup-ai -sll` prints this arithmetic before writing anything:

```
📦 Qwen3.6 35B-A3B MTP MoE [4-bit, 21.11 GiB]
🧠 KV q8_0 @ 65536 ctx = 1.32 GiB | footprint ≈ 23.4 GiB (weights 21.11 GiB + KV + 1 GiB buffers)
```

Worked example on a **32 GiB** box with the 21.11 GiB `UD-Q4_K_M` weights - about
9 GiB left, of which ~1 GiB is compute:

| ctx   | `q8_0`   | `f16`    |
| ----- | -------- | -------- |
| 32 k  | 0.66 GiB | 1.25 GiB |
| 128 k | 2.65 GiB | 5.00 GiB |

128 k context is comfortable here. On a 16 GiB box the same model would not load
at all - which is why the picker flags fit instead of guessing.

---

## The knobs, and what they actually do

### Weights - `LLAMACPP_MODELS`

One catalog line is `(model, quantisation)`:

```
id | display | hf_repo | quant | size_gib | kv_kib | ctx_max | reasoning | tier
```

The **tier** is the 3-bit / 4-bit / 6-bit / 8-bit choice. Lower bits = smaller
and usually faster, with some quality cost. The `id` is the model name your
clients see, so it is stable across quant changes.

`kv_kib` is derived per model from `2 × layers × kv_heads × head_dim × 2 bytes`
and is what makes the context solver correct.

> The `quant` column must match a real filename in the repo. llama.cpp greps for
> `<quant>.` / `<quant>-` and **fails the download** when nothing matches, so a
> typo is a loud error rather than a silent wrong-file fetch.

### Context window - `LLAMACPP_CTX_CHOICES`, `LLAMACPP_CTX_DEFAULT`

The offered sizes. `ctx_max` per model caps them (a model never gets offered
more context than it supports), and the solver clamps to what RAM allows.

With `LLAMACPP_N_PARALLEL=1` a request gets the whole window. Raising it splits
the shared KV pool: `parallel=2` roughly halves per-request context.

### Prediction - `LLAMACPP_SPEC_TYPE`

Speculative decoding drafts several tokens and verifies them in one batch. It
speeds up **generation**, not prompt processing.

- `ngram-simple` - **default.** Matches n-grams already in this conversation.
  No extra model, no extra RAM. Best for editing code, where you repeat a lot.
- `draft-simple` - a small standalone draft model. Costs RAM. Set
  `LLAMACPP_SPEC_DRAFT` to `owner/repo:Q4_K_M`; use the same family as the
  target or acceptance collapses.
- `draft-mtp` - for `-MTP-` models that carry their own multi-token head.
- `none` - off.

### GPU - `LLAMACPP_NGL`, `LLAMACPP_SPLIT_MODE`, `LLAMACPP_TENSOR_SPLIT`

Ignored on a CPU-only build.

- `LLAMACPP_NGL=auto` offloads as much as fits, `all` offloads everything, or an
  integer keeps that many layers on the GPU. `auto` is usually right; pin it only
  if you want the CPU kept free for other work.
- `LLAMACPP_TENSOR_SPLIT` is only for **more than one** GPU, as fractions, e.g.
  `"0.6,0.4"` for a 16 GB + 8 GB pair. Leave empty to let llama.cpp decide.

### Vision - `LLAMACPP_MMPROJ`

`0` skips the mmproj projector (less RAM and disk, text only). `1` downloads it
when the repo has one and enables image input over the API.

### Auto load / router - `LLAMACPP_ROUTER`

- `0` - classic. Serves exactly the model you picked; switching means re-running
  `-sll`.
- `1` - **router mode** (default). One endpoint serves **every** catalog model,
  loading each on demand and evicting past `LLAMACPP_MODELS_MAX`. The model id in
  `/v1/models` is the INI section name, so a model with several quant tiers is
  exposed as `qwen3.6-35b-a3b-mtp@UD-Q4_K_M` - the client can pick the weight
  tier too, and all of them show up in the opencode model picker.

Because router mode swaps weights in and out, size `LLAMACPP_MODELS_MAX` for your
RAM: each resident model holds its own weights **and** its own KV cache. Keep
`load-on-startup = false` (already set) so nothing loads at boot.

---

## Operating it

```sh
systemctl --user restart llamacpp        # apply env changes
systemctl --user status llamacpp
journalctl --user -u llamacpp -f
curl http://127.0.0.1:8080/v1/models     # what is actually served
```

### Accessing it from the console

```sh
# one-time: load the key into your shell
export LLAMACPP_API_KEY=$(grep -vE '^[[:space:]]*(#|$)' ~/.config/llamacpp/api-key | head -n1)

# list models and whether each is loaded
curl -s -H "Authorization: Bearer $LLAMACPP_API_KEY" \
  http://127.0.0.1:8080/v1/models | jq -r '.data[] | "\(.id)\t\(.status.value)"'

# chat (the model id is the preset section name, e.g. lfm25-2.6b@Q4_K_M)
curl -s -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Authorization: Bearer $LLAMACPP_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"lfm25-2.6b@Q4_K_M","messages":[{"role":"user","content":"hello"}]}'
```

Router mode routes by the `model` field, so **GET endpoints need `?model=`**:

```sh
curl -H "Authorization: Bearer $LLAMACPP_API_KEY" \
  'http://127.0.0.1:8080/metrics?model=lfm25-2.6b@Q4_K_M'
```

`/metrics` without it returns `400 model name is missing from the request`, which
is expected, not a failure.

### Reading a response

`llama-server` returns standard OpenAI fields plus two llama.cpp extras worth
knowing:

```jsonc
{
  "choices": [
    {
      "message": {
        "content": "...", // the answer
        "reasoning_content": "...", // thinking trace, when the model emits one
      },
    },
  ],
  "usage": { "completion_tokens": 58 }, // includes reasoning tokens
  "timings": {
    // llama.cpp extra, humans only
    "predicted_per_second": 2.76, // generation rate
    "prompt_per_second": 3.31, // prompt processing rate
  },
}
```

Two things that catch people out:

- **`max_tokens` covers thinking too.** A reasoning model spends the first part
  of its budget on `reasoning_content`. Asking for 30 tokens on `lfm25-2.6b` can
  return an empty `content` with a complete trace beside it. Budget for it, or use
  `--reasoning-budget` / `-rea off` to suppress thinking.
- **`reasoning_content` is per model, not per family.** Verified on this pin:
  `lfm25-2.6b` returns it, `lfm25-1.2b-instruct` does not. llama.cpp enables it
  when the chat template supports it (`-rea auto`). The catalog `reasoning` column
  drives how opencode presents thinking; it does not force a model to think.

Because reasoning is preserved in history by default, it consumes context. With a
small `ctx`, disable it per model in the preset with `reasoning-preserve = false`.

The `timings` block is why `llama-bench` and the API agree, and it is the quickest
way to tell a slow model from a slow machine. On a CPU without AVX/FMA, ggml
falls back to scalar kernels and a few tokens/second is normal - `-sll` reports the
SIMD features it found.

For a terminal chat without the HTTP server at all, `llama-cli` downloads and runs
a model directly - it does not go through the router and does not use the service:

```sh
llama-cli -hf LiquidAI/LFM2.5-2.6B-GGUF:Q4_K_M -c 8192
llama-bench -hf LiquidAI/LFM2.5-2.6B-GGUF:Q4_K_M -p 512
```

Both share `LLAMA_CACHE`, so anything fetched once is reused. Running `llama-cli`
while the service holds the same weights will fight over RAM - stop the unit first
(`systemctl --user stop llamacpp`).

## Reaching it from other machines

The bind address is chosen with `fzf` during `setup-ai -sll`, so you see what the
machine actually owns instead of guessing:

```
> Which addresses may reach the API?
  127.0.0.1          | local only | this machine
  0.0.0.0            | all IPv4 interfaces | LAN + anything routable to this host
  192.168.111.208    | ens18 | private address
  172.17.0.1         | docker0 | private address
```

The list is built from the host's global-scope IPv4 addresses, each labelled with
its interface and whether it is `private`, `link-local` or `PUBLIC`, so an
internet-routable address is obvious before you commit to it.

- **loopback** - only this machine (the default).
- **a specific address** - only its own subnet; nothing else on the box listens.
- **wildcard (`0.0.0.0`)** - every host that can route here.

Re-run `setup-ai -sll` at any time to change it. `LLAMACPP_BIND` in
`ai/setup-ai-llamacpp.conf` is only the value pre-selected in the picker.

Keep `LLAMACPP_API_KEY=1` when you leave loopback. Without a key anything routable
can spend this host's RAM and GPU, and can trigger a multi-GB model download. The
setup warns if you bind a non-private address with auth disabled.

Clients then use `http://<address>:8080/v1` with the same `Authorization: Bearer`
header. For a terminal chat without the HTTP server at all, `llama-cli` downloads
and runs a model directly - it does not go through the router and does not use
the service:

```sh
llama-cli -hf LiquidAI/LFM2.5-2.6B-GGUF:Q4_K_M -c 8192
llama-bench -hf LiquidAI/LFM2.5-2.6B-GGUF:Q4_K_M -p 512
```

Both share `LLAMA_CACHE`, so anything fetched once is reused. Running `llama-cli`
while the service holds the same weights will fight over RAM - stop the unit first
(`systemctl --user stop llamacpp`).

To open it to the wider internet, put it behind a reverse proxy with TLS and
restrict the source address - do not expose llama-server directly.

> Clients configured locally (opencode, the verify command above) never use the
> wildcard address: a `0.0.0.0` bind includes loopback, so they connect to
> `127.0.0.1`. With a specific-address bind they must use that same address,
> because nothing is listening on loopback in that case.

### Authentication

`LLAMACPP_API_KEY=1` (the default) generates a 48-char key on the first
`setup-ai -sll` and stores it at `~/.config/llamacpp/api-key` with mode `600`. That
file is the single source of truth and is never committed; the env file only
references it via `LLAMA_ARG_API_KEY_FILE`. Rotate by deleting the file and
re-running `setup-ai -sll`.

`/health` stays public by design (that is what health checks are for);
everything else returns `401` without the header.

opencode is wired to the same key through the config in
`ai/setup-ai-opencode.conf`, which references `{env:LLAMACPP_API_KEY}` rather than
embedding the secret. Export it from your shell profile:

```sh
export LLAMACPP_API_KEY=$(grep -vE '^[[:space:]]*(#|$)' ~/.config/llamacpp/api-key | head -n1)
```

### Reading the logs

After a restart plus a model load you should see **no errors and only two
warnings** (`LLAMA_ARG_HOST` / `LLAMA_ARG_PORT` are set, but will be overwritten by
command line argument). Those two cannot be avoided: the router binds its own
listener from the environment _and_ forwards those flags to each child.

Everything else you may still see, and why:

Router mode probes every preset at startup, and reports the outcome at error level
even when nothing is wrong. Both of these are harmless; neither stops a model
from loading:

- `gguf_init_from_file: failed to open GGUF file '<repo>:<quant>'` - one per
  catalog model that is not downloaded yet. `/v1/models` shows it as `unloaded`
  until a request names it, at which point it downloads and loads fine.
- `common_download_get_hf_plan: no GGUF files found in repository <repo>` -
  emitted for models that **are** cached. Confirmed non-fatal: the cached file is
  then used and the model loads normally.

Check `/v1/models` rather than the log to decide whether something is wrong.

- `security: router mode enabled` - true and worth keeping in mind; see
  [Authentication](#authentication) above.
- `server default port will be changed to :9931` - upstream FYI. The port here is
  set explicitly, so it will not move.

GPU options (`--gpu-layers`, `--split-mode`) are only written into the env file
when the build actually has a GPU backend, so a CPU-only build stays quiet.

In router mode the context size, KV type and slot count live in the preset `[*]`
block rather than the env file, because the router passes them to each child as
command line arguments. Setting both makes every child warn about the override.

### Hardening notes

- CORS is derived from the bind address: `localhost` for loopback and wildcard
  binds, otherwise the single origin `http://<bind>:<port>`. It only affects
  browsers - curl, opencode and the SDKs never send an `Origin` header.
- Set `LLAMACPP_CORS_ORIGINS` to one exact origin if a page served from another
  host must call the API. **One value, not a comma list**: llama.cpp treats
  anything that is not `*` or `localhost` as a single literal header value, so a
  comma-joined list silently blocks every browser.
- The generated `llamacpp.env` and `api-key` are both mode `600`. Neither is ever
  committed - the key is generated on the machine, not stored in the repo.
- `--sleep-idle-seconds` has no `LLAMA_ARG_*` form, so it cannot be set from the
  env file; add it to `ExecStart` in the unit if you want it.
- Check RAM per token yourself with `llama-bench`.
