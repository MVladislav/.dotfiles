# OPNsense API — onboarding flow

Source: https://docs.opnsense.org/development/api.html

A compact flow for first-time users of the OPNsense API. Use it to introduce
the API: high-level capabilities, one minimal read-only `curl`, and a fork to
steer the user toward their first real request.

## Flow

1. **Stay scoped to OPNsense.**
2. In ≤4 bullets, tell the user what the OPNsense API can do at a high level
   (capabilities, not endpoint lists): firewall/NAT/alias inspection, interface
   and routing status, DHCP/DNS, IPsec/OpenVPN/WireGuard status, and system
   firmware/status, all over JSON.
3. Show one minimal, copy-pasteable `curl` example: `-u` basic auth using the
   API key/secret plus one safe read-only call (`/api/core/firmware/status`).
   Point out where the key/secret are generated (System → Access → Users →
   key icon; secret shown once).
4. End with exactly this fork — let the user pick:
   a) Walk me through my first authenticated call
   b) Help me find endpoints for a specific capability (I'll name it)
   c) Build a recipe for a specific goal (I'll describe it)
5. If a goal reaches beyond OPNsense (e.g. ESXi, UniFi), mention it in passing
   and note the other skill/API that covers it.

## Minimal read-only example

```sh
curl -sS -u "$OPNSENSE_API_KEY:$OPNSENSE_API_SECRET" \
  "$OPNSENSE_URL/api/core/firmware/status"
```
