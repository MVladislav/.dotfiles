---
name: opnsense
description: Read-only OPNsense firewall configuration via its REST API (firewall, interfaces, NAT, DHCP, VPN, routing, system) using an API key/secret pair
license: MIT
compatibility: opencode
metadata:
  audience: network-admins
  workflow: opnsense
---

## What I do

Inspect and help maintain an OPNsense firewall over its read-only REST API:
firewall aliases and rules, NAT, interfaces, DHCP/Kea/DNS, VPN (IPsec, OpenVPN,
WireGuard), routing, and system status. Reads only — I never change config or
trigger actions through the API.

Prerequisites: three env vars set:

- `OPNSENSE_URL` — the firewall base URL, e.g. `https://192.168.1.1`.
- `OPNSENSE_API_KEY` — the API key (used as the basic-auth username).
- `OPNSENSE_API_SECRET` — the API secret (used as the basic-auth password).

The key/secret pair are the OPNsense API credentials. They are granted to a
bound user and inherit that user's privileges, so a **read-only key** is one
whose user has only read (pull) privileges — see below.

If any of these is missing, stop and tell the user how to generate the key and
set the env vars — do not guess credentials.

Two companion files live in this skill folder:

- `API.md` — vendored endpoint reference (from the official API docs): the
  common read-only (`GET`) surface by module/controller, and the URL pattern.
- `ONBOARDING.md` — a compact onboarding flow for first-time API users
  (high-level capabilities, one read-only curl, pick-a-path fork).

---

## Creating a read-only API key (if none is granted)

OPNsense API keys are tied to a user and inherit that user's privileges, so
read-only access is enforced at the user/group level, not at the key level.
Follow least privilege **and** add the deny-write backstop:

1. **Create a dedicated read-only user** (**System → Access → Users → +**).
   Do not reuse an admin/an admins-group user — the key would inherit full
   admin rights.

2. **Grant that user ONLY the read / search / diagnose privileges you actually
   need**, and none of the write/edit/action privileges. From the privilege list
   (System → Access → Privileges), read-only-friendly picks include:
   - `page-status-*` — Status pages (Interfaces, Services, IPsec, OpenVPN,
     Gateways, NTP, DHCP...) — view-only.
   - `page-diagnostics-*` — Diagnostics (logs: System/Firewall/Gateways,
     Netstat, ARP/NDP tables, Routing tables, Show States, System Health,
     System Activity, Ping, Traceroute) — read/query only.
   - `page-system-login-logout` — "Lobby: Dashboard" (required to log in +
     system info read endpoints) — grants the dashboard and basic
     `api/diagnostics/system/*` reads.
   - `page-firewall-aliases` / `page-filter-api` / `page-firewall-nat-*` may
     seem like reads, but the `api/.../*` globs inside them cover the
     write endpoints too. **Prefer the diagnostics/status picks unless you
     specifically need alias/filter reads**, and when you do need them,
     combine with `user-config-readonly` (below).
   - `page-status-services`/`page-core-*` equivalent reads under
     `api/core/service/*` can start/stop services, so avoid unless scoped.

   Keep the grant minimal: only what the read-only workflow will actually call.
   A user with **no** write component privileges cannot reach most mutators at
   all.

3. **Add the deny-write backstop**: assign the user the privilege
   `user-config-readonly` — **"System: Deny config write"**. This is the
   explicit read-only switch: it makes the normal MVC save path reject config
   writes even where a component privilege is present.
   ⚠️ Caveats (know these, they are real):
   - It is **not a hard guarantee** — some controllers persist via
     `Config::save()` directly and bypass the check (OPNsense security
     advisories GHSA-vw8q-pqq7-2q7v and GHSA-p9pr-782r-w2xw). It is
     **defense-in-depth**, not a guarantee.
   - It is flagged for possible **removal in a future release**.
   - So the **real** read-only protection is step 2 (simply not granting write
     privileges); `user-config-readonly` just adds a second layer.

4. **Generate the API key** for that user (**System → Access → Users →** key
   icon on the user row). The secret is shown **only once at creation** — save
   it into the environment immediately:

   ```
   export OPNSENSE_URL='https://<firewall-host>'
   export OPNSENSE_API_KEY='<key>'
   export OPNSENSE_API_SECRET='<secret>'
   ```

   If the key is lost the secret cannot be recovered; generate a new one.

5. **Verify it is read-only** (the agent does this in the Confirm access step):
   a known read succeeds, and a known write returns an access-denied
   (`401`/`403`/"denied") rather than `200`/`saved`. Only trust the key once a
   harmless write probe is denied.

---

## Step-by-step

Auth is HTTP Basic on every request, with the key as username and secret as
password:

```sh
curl -sS -u "$OPNSENSE_API_KEY:$OPNSENSE_API_SECRET" \
  "$OPNSENSE_URL/api/core/firmware/status"
```

1. **Confirm access** with an unconditional read endpoint:

   ```sh
   curl -sS -u "$OPNSENSE_API_KEY:$OPNSENSE_API_SECRET" \
     "$OPNSENSE_URL/api/core/firmware/status"
   ```

   A `200` with JSON means the key works; a `401`/`403` means the key is
   missing, invalid, or lacks access — report that to the user.

2. **Verify it is actually read-only.** Reading works ≠ read-only. After the
   read succeeds, issue one **harmless write probe** that a read key must
   reject — e.g. a no-op `POST` to a keep-alive / status echo that does not
   change state, then confirm the response is an access denial (`401`/`403` or
   `"denied"`), never `200`/`saved`. If a write is accepted, do **not** trust
   the key as read-only: stop and tell the user their key/user has write
   privileges. Pick a probe that cannot mutate anything (never use
   `.../add`, `.../del`, `.../reboot`, or `.../set`).

3. **Probe what the key can actually read.** Because privileges vary per user,
   don't assume all documented endpoints are reachable; try a known `GET` in
   each area you need and treat a `403` as "not granted".

4. **Read configuration.** All paths look like
   `{OPNSENSE_URL}/api/<module>/<controller>/<command>`; the common read-only
   (`GET`) surface is in `API.md`. Representative calls:

   ```sh
   # firmware + system status
   curl -sS -u "$k:$s" "$OPNSENSE_URL/api/core/firmware/status"
   curl -sS -u "$k:$s" "$OPNSENSE_URL/api/core/system/status"

   # interfaces
   curl -sS -u "$k:$s" "$OPNSENSE_URL/api/diagnostics/interface/getInterfaceStatistics"

   # routing / routes
   curl -sS -u "$k:$s" "$OPNSENSE_URL/api/routes/status"

   # firewall aliases (searchPattern JSON body, POST even though read-only-ish)
   curl -sS -u "$k:$s" -H 'Content-Type: application/json' \
     -d '{"current":1,"rowCount":100,"searchPhrase":""}' \
     "$OPNSENSE_URL/api/firewall/alias/searchItem"
   ```

   Pipe through `jq` to shape output.

5. **Explain / recommend** from the data: summarize the firewall, NAT, and
   interface state; identify anomalies; then describe what you would change and
   why.

---

## Constraints

- **Read-only.** Only issue `GET` calls (and search-style `POST` calls that
  only query data, e.g. `.../searchItem` with no mutation). Never call write or
  action endpoints — `POST`/`GET` to handlers that create, update, delete,
  reconfigure, restart, reboot, or otherwise change state (e.g.
  `.../add`, `.../set`, `.../del`, `.../reconfigure`, `.../revert`,
  `.../restart`). Express any intended change as a manual step for the user in
  the OPNsense UI.
- **Read-only is defense-in-depth, not guaranteed.** OPNsense enforces it via
  least-privilege (user granted only read/search/diagnose privileges) plus the
  `user-config-readonly` "Deny config write" privilege, which is a backstop
  with known write bypasses (GHSA-vw8q-pqq7-2q7v, GHSA-p9pr-782r-w2xw) and may
  be removed in a future release. Never treat the key as a hard read-only
  boundary; the skill's own `GET`-only discipline is the primary safeguard.
- Never echo `OPNSENSE_API_KEY` or `OPNSENSE_API_SECRET`; they are secrets.
- If `curl`, `jq`, or the env vars are missing, stop and tell the user what to
  install/set rather than improvising.
- OPNsense has no single served API spec on the console (unlike some platforms);
  use `API.md` + the online docs
  (https://docs.opnsense.org/development/api.html) for endpoint shapes.
- Stay scoped to OPNsense. Do not reach into other systems unless asked.
