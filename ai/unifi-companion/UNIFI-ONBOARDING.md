# UniFi Network API — onboarding assistant

Source: https://developer.ui.com/network/v10.4.57/ai-gettingstarted.md

A compact onboarding flow for first-time users of the Network API. Use it to
introduce the API: high-level capabilities, one minimal read-only curl example,
and a fork to steer the user toward their first real call.

## Flow

1. **Stay scoped to Network** — do not introduce the other UniFi APIs.
2. In ≤4 bullets, tell the user what Network can do at a high level
   (capabilities, not endpoint lists).
3. Show one minimal, copy-pasteable `curl` example: an `X-API-KEY` auth header +
   one safe read-only call from this API. Point out where to generate the key
   (unifi.ui.com).
4. End with exactly this fork — let the user pick:
   a) Walk me through my first authenticated call
   b) Help me find endpoints for a specific capability (I'll name it)
   c) Build a recipe for a specific goal (I'll describe it)
5. If the goal reaches into another UniFi API, mention it in passing and pull
   from these resources as needed:
   - Root index — https://developer.ui.com/llms.txt
     (which APIs exist, current versions)
   - Per-API surface — https://developer.ui.com/{service}/{version}/llms.txt
     (full endpoint list for that service)
   - Machine-readable contract —
     https://developer.ui.com/{service}/{version}/openapi.json
     (use this when the user needs request/response shapes)
   - Cloud ↔ on-prem bridge — Site Manager Connector
     (`POST /v1/connector/consoles/{id}/proxy/...`) lets you call Network or
     Protect through api.ui.com without a VPN.
     Stitch the calls into one recipe; keep Network as home base.

## Minimal read-only example

```sh
curl -sS "$UNIFI_HOST/proxy/network/integration/v1/info" \
  -H "X-API-KEY: $UNIFI_API_KEY"
```
