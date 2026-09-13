---
name: unifi
description: Inspect UniFi OS Network configuration via the Network Integration API (sites, devices, clients, networks, firewall, wifi, vpn) using an API key; read-only by discipline
license: MIT
compatibility: opencode
metadata:
  audience: network-admins
  workflow: unifi
---

## What I do

Inspect UniFi OS network configuration over the Network Integration API: list
sites, adopted devices, connected clients, networks, firewall policies, wifi
broadcasts, VPN tunnels, and more. This skill is **read-only by convention** —
it only issues `GET` calls and never changes network state through the API.

> ⚠️ Important: a UniFi Network API key is **not** read-only by itself. UniFi
> only lets you set **Name, Description, and Expiry** at key creation — there is
> **no read-only toggle and no per-endpoint scope**, so the key can technically
> read and write everything. The read-only guarantee comes **only from this
> skill's own discipline** (GET-only). Never call a write endpoint, even though
> the key would allow it.

Prerequisites — two env vars set:

- `UNIFI_API_KEY` — a Network Integration API key.
- `UNIFI_HOST` — the console base URL, e.g. `https://192.168.1.1` or
  `https://<name>.ui.com`. When set, the skill builds URLs like
  `${UNIFI_HOST}/proxy/network/integration/v1/...`.

If either is missing, stop and tell the user how to create the key (below) and
set the env vars — do not guess credentials or poke at the UI.

Two companion files live in this skill folder:

- `UNIFI-API.md` — vendored endpoint reference (llms.txt, v10.4.57): every
  Network endpoint with its verb; use it to look up exact paths and confirm the
  read-only (`GET`-only) surface.
- `UNIFI-ONBOARDING.md` — vendored onboarding flow (ai-gettingstarted.md):
  the recommended intro flow for first-time API users (capabilities, one
  read-only curl, and the pick-a-path fork), plus the Site Manager Connector
  note for reaching other UniFi surfaces via the cloud bridge.

Besides the vendored companions, each console serves its own API description at
`{UNIFI_HOST}/unifi-api/network` — the Network API docs **for the exact version
running on that console** (it can differ from the vendored 10.4.57 reference).
Use it to confirm version-specific endpoints and auth notes against the live
console:

```sh
curl -sS "$UNIFI_HOST/unifi-api/network" -H "X-API-KEY: $UNIFI_API_KEY"
```

If the live console's API surface diverges from the vendored `UNIFI-API.md`,
trust the console copy (it reflects what is actually installed).

---

## Creating the API key (if none is granted)

1. Log in to the UniFi OS console (UDM/UDW/UCG/CloudKey).
2. Open the **Network** app → **Settings** → **Integrations** (URL:
   `<UNIFI_HOST>/network/default/integrations`), then **Create API Key** or
   **Integrate with external apps**.
3. Fill in the fields — UniFi offers **only**:
   - **Name**
   - **Description**
   - **Expiry**
     There is **no read-only toggle and no access-scope picker**. The key gets
     access to the integration endpoints as-is. (If you have newer firmware that
     adds a scope option, use the most restrictive one, but do not rely on it.)
4. Copy the key into the environment immediately (the full key is shown at
   creation):

   ```sh
   export UNIFI_API_KEY='<key>'
   export UNIFI_HOST='https://<console-host>'
   ```

   (Add both to your shell/profile if you want it to persist.)

---

## Step-by-step

Auth is a single header on every request:

```sh
curl -sS "$UNIFI_HOST/proxy/network/integration/v1/info" \
  -H "X-API-KEY: $UNIFI_API_KEY"
```

1. **Confirm access** first with an unconditional read endpoint:

   ```sh
   curl -sS "$UNIFI_HOST/proxy/network/integration/v1/info" \
     -H "X-API-KEY: $UNIFI_API_KEY"
   ```

   A non-empty JSON body means the key works; a `401`/`403` means the key is
   missing, invalid, or lacks access to that endpoint — report that to the user.
   A working key does **not** mean it is read-only: UniFi keys are full-access,
   so assume the key can write and rely on the skill's GET-only discipline.

2. **Find the site(s)**: `GET /v1/sites` returns the sites and their `siteId`.
   Every site-scoped call needs a `siteId`:

   ```sh
   curl -sS "$UNIFI_HOST/proxy/network/integration/v1/sites" \
     -H "X-API-KEY: $UNIFI_API_KEY"
   ```

3. **Read configuration** scoped to a site. All paths resolve under
   `/proxy/network/integration/v1`; the full read-only surface is in
   `UNIFI-API.md` (fetch context from it when an exact path is needed).
   Common read-only endpoints:
   - Devices: `GET /v1/sites/{siteId}/devices` (adopted devices),
     `.../devices/{deviceId}` (details),
     `.../devices/{deviceId}/statistics/latest` (live stats),
     `GET /v1/pending-devices` (unadopted).
   - Clients: `GET /v1/sites/{siteId}/clients`, `.../clients/{clientId}`.
   - Networks: `GET /v1/sites/{siteId}/networks`, `.../networks/{networkId}`,
     `.../networks/{networkId}/references`.
   - Firewall: `GET /v1/sites/{siteId}/firewall/policies`,
     `.../firewall/policies/{firewallPolicyId}`,
     `GET /v1/sites/{siteId}/firewall/zones`.
   - WiFi: `GET /v1/sites/{siteId}/wifi/broadcasts`,
     `.../wifi/broadcasts/{wifiBroadcastId}`.
   - VPN/WAN: `GET /v1/sites/{siteId}/vpn/servers`,
     `.../vpn/site-to-site-tunnels`, `GET /v1/sites/{siteId}/wans`.
   - Sharing/LAGs/ACLs/DNS: `GET /v1/sites/{siteId}/switching/lags`,
     `.../acl-rules`, `.../dns/policies`, `.../radius/profiles`,
     `.../traffic-matching-lists`, `.../device-tags`. **Note:** several of these
     `switching/...` paths are absent on some console versions (404) — treat
     them as best-effort, not guaranteed.
   - Supporting reads: `GET /v1/countries`, `GET /v1/dpi/applications`,
     `GET /v1/dpi/categories`.

   For a first-time API user, use the onboarding flow in `UNIFI-ONBOARDING.md`
   (one minimal read-only curl + the pick-a-path fork).

   Pipe through `jq` to shape output, e.g.:

   ```sh
   curl -sS "$UNIFI_HOST/proxy/network/integration/v1/sites/$SITE_ID/networks" \
     -H "X-API-KEY: $UNIFI_API_KEY" | jq '.data[] | {name, vlanId, management}'
   ```

   **Pagination tip:** list endpoints return a page envelope
   `{offset, limit, count, totalCount, data}` and **default to `limit: 25`**.
   `totalCount` is the true number of records — if it differs from the number
   of `data` rows, refetch with a larger limit. Always include the limit to
   avoid silently missing clients/devices:

   ```sh
   curl -sS ".../clients?limit=100" -H "X-API-KEY: $UNIFI_API_KEY" \
     | jq '{totalCount, returned: (.data|length)}'
   ```

   **Field names on this API (not the classic Unifi API):**
   - Clients use `ipAddress`/`macAddress` (not `ip`/`mac`), plus
     `type` (`WIRED`/`WIRELESS`), `uplinkDeviceId`, `connectedAt`.
   - Devices: `ipAddress`, `macAddress`, `uplink.deviceId`,
     `.interfaces.{ports|radios}`, `state` (`ONLINE`/`OFFLINE`),
     `firmwareVersion`; port info at `.interfaces.ports[]` with `idx`,
     `state` (`UP`/`DOWN`), `connector`, `speedMbps`, `poe.{standard|enabled}`.
   - Networks: `name`, `vlanId`, `management`, `metadata.origin`
     (`SYSTEM_DEFINED`/`USER_DEFINED`). **Subnet/gateway are NOT returned on
     this API** — infer subnets from client `ipAddress` octets (e.g. all
     `192.168.40.x` ⇒ VLAN 40 is `192.168.40.0/24`).
   - WiFi: `wifi/broadcasts` items have `type` (`STANDARD`/`IOT_OPTIMIZED`),
     `network.networkId`, `securityConfiguration.type`, and
     `broadcastingFrequenciesGHz`. An `IOT_OPTIMIZED` broadcast may embed
     **multiple SSIDs via `presharedKeys[]`** each mapping a passphrase to a
     different network/VLAN — treat these as plaintext secrets and **never
     echo the passphrases**.

4. **Identify the console first.** The integration `info` returns only
   `applicationVersion`, so identify the host separately: check for dedicated
   hardware (CloudKey `UCK`/`UDM`) vs a virtualised **UniFi OS Server (UOS
   VM)**. A lab may run **multiple consoles** — e.g. a Network-only UOS VM plus
   a separate Protect-only UCK for cameras. Confirm which console/site you are
   querying and note that unrelated apps (Protect, Access) on other consoles
   are different sites not covered here.

5. **Handle / interpret common non-200 responses instead of assuming success:**
   - `400 code=api.firewall.zone-based-firewall-not-configured` from
     `firewall/policies` + `firewall/zones` ⇒ the site uses **classic (non-ZBF)
     firewall rules**, which this integration API does **not** expose. Firewall
     enforcement must be reviewed elsewhere (e.g. OPNsense).
   - `404 "No endpoint GET ..."` from `switching/{acl-rules,dns-policies,
radius-profiles,traffic-matching-lists,port-profiles}` ⇒ those paths don't
     exist on this console version. Don't treat as a config result; just skip.
   - Empty lists (`count: 0`) for `wans`, `vpn/*`, `switching/lags` are valid —
     no WAN/VPN/LAG configured.
   - `401`/`403` ⇒ key missing/invalid or lacks access.

6. **Explain / recommend** from the data: summarize the current topology,
   identify adoptable `pending-devices`, stale/offline devices, and the
   per-VLAN client distribution (group clients by the subnet their IP falls in)
   — then describe what you would change and why. For clients that appear
   **MAC-only** (bare `aa:bb:cc:dd:ee:ff` names, no friendly hostname), enrich
   by looking up the OUI (first 3 octets) via a MAC vendor API to suggest what
   the device is (e.g. `b8:68:70` = Nintendo, `ec:c3:02` = HUMAX).

---

## Constraints

- **Read-only by discipline, not by key.** A UniFi Network API key is
  full-access (only Name/Description/Expiry at creation). The read-only
  guarantee comes **entirely** from this skill: only use `GET` endpoints. Never
  call the write verbs (`POST`/`PUT`/`PATCH`/`DELETE`, e.g. adopt devices,
  create/edit networks, firewall policies, vouchers, wifi broadcasts, client
  actions). Write intents must be handed to the user as manual steps in the
  Network UI.
- Never echo `UNIFI_API_KEY`; it is a secret. If you must debug, mask it.
- WiFi broadcast details may return **plaintext Wi-Fi passphrases**
  (`securityConfiguration.presharedKeys[].passphrase`), including for
  `IOT_OPTIMIZED` multi-SSID broadcasts. Do not echo these; summarize with
  placeholders and hand creation of new ones to the user as UI steps.
- If `curl`, `jq`, or the env vars are missing, stop and tell the user what to
  install/set rather than improvising.
- Stay scoped to the Network API. Other UniFi surfaces (Protect, Access,
  Site Manager cloud API) are out of scope unless the user explicitly asks.
