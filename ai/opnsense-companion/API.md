# OPNsense REST API — read-only reference

Source: https://docs.opnsense.org/development/api.html

URL pattern: `https://<host>/api/<module>/<controller>/<command>[/<param1>/...]`

Auth: HTTP Basic Auth — `OPNSENSE_API_KEY` as username, `OPNSENSE_API_SECRET`
as password. Both are shown only once at key creation.

Verbs:

- `GET` — retrieve data.
- `POST` — create, update, execute, **or query lists**. Note many list/search
  endpoints are `POST` with a JSON grid body (`{"current":1,"rowCount":100,...}`)
  yet are read-only in effect — treat `.../search` / `.../searchItem` /
  `.../get...` as reads; treat `.../add`, `.../set`, `.../del`, `.../reconfigure`,
  `.../restart`, `.../revert`, `.../reboot`, `.../halt` as writes.

Effective Privileges on the bound user decide what a key may access; a `403`
means the key/user lacks that endpoint.

## Core — system & diagnostics

| Module | Controller | Command           | Method     | Read-only |
| ------ | ---------- | ----------------- | ---------- | --------- |
| core   | firmware   | status            | GET        | yes       |
| core   | system     | status            | GET        | yes       |
| core   | service    | search            | POST(grid) | query     |
| core   | dashboard  | get_dashboard     | GET        | yes       |
| core   | dashboard  | product_info_feed | GET        | yes       |
| core   | menu       | tree              | GET        | yes       |

## Firewall

| Module   | Controller | Command    | Method         | Read-only |
| -------- | ---------- | ---------- | -------------- | --------- |
| firewall | alias      | searchItem | GET/POST(grid) | query     |
| firewall | alias      | getItem    | GET            | yes       |
| firewall | filter     | searchRule | GET/POST(grid) | query     |
| firewall | filter     | getRule    | GET            | yes       |
| firewall | nat        | searchRule | GET/POST(grid) | query     |
| firewall | nat        | getRule    | GET            | yes       |

## Interfaces / routing / diagnostics

| Module      | Controller  | Command                | Method | Read-only |
| ----------- | ----------- | ---------------------- | ------ | --------- |
| interfaces  | diagnostics | getInterfaceStatistics | GET    | yes       |
| routes      | status      | index                  | GET    | yes       |
| diagnostics | traffic     | top                    | GET    | yes       |
| diagnostics | tables      | list                   | GET    | yes       |

## DHCP / DNS / services (Kea, Unbound, dnsmasq)

| Module  | Controller | Command           | Method         | Read-only |
| ------- | ---------- | ----------------- | -------------- | --------- |
| kea     | dhcpv4     | searchLease       | GET/POST(grid) | query     |
| kea     | dhcpv4     | searchReservation | GET/POST(grid) | query     |
| kea     | dhcpv6     | searchLease       | GET/POST(grid) | query     |
| unbound | service    | searchDnsEntry    | GET/POST(grid) | query     |

## VPN

| Module    | Controller | Command              | Method         | Read-only |
| --------- | ---------- | -------------------- | -------------- | --------- |
| ipsec     | legacy     | getStatus            | GET            | yes       |
| openvpn   | service    | searchClientInstance | GET/POST(grid) | query     |
| wireguard | server     | get                  | GET            | yes       |
| wireguard | client     | get                  | GET            | yes       |

## Notes

- Response bodies are JSON. For search endpoints the typical request body is
  `{"current":1,"rowCount":<n>,"sort":{},"searchPhrase":""}` and the response is
  `{"total":..,"rowCount":..,"current":..,"rows":[..]}`.
- Grid/`searchItem` calls are `POST` but query-only; they are safe for a
  read-only workflow. Nothing on this reference page mutates state.
- The authoritative per-endpoint docs are generated at
  https://docs.opnsense.org/development/api.html (core + plugins). Versions may
  add/rename endpoints; verify against the live firewall.

## Read-only access model (privileges)

API keys inherit the bound user's privileges. Read-only = **least privilege**
(bind a user with only read/diagnose privileges, never write/edit ones) plus
the `user-config-readonly` deny-write backstop.

Key privileges (System → Access → Privileges):

| Priority for read-only  | Privilege id                                         | Name                                                                                           | What it grants (match globs)                                                                                      |
| ----------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| required to log in      | `page-system-login-logout`                           | Lobby: Dashboard                                                                               | login + `api/core/dashboard/*`, `api/diagnostics/system/*`, `api/diagnostics/cpu_usage/*`                         |
| pick (view-only)        | `page-diagnostics-*`                                 | Diagnostics (ARP, NDP, Netstat, Routing tables, Show States, System Health, Activity, logs...) | `api/diagnostics/*` reads/queries                                                                                 |
| pick (view-only)        | `page-status-*`                                      | Status: Interfaces / Services / IPsec / OpenVPN / Gateways / NTP                               | `api/.../*` status reads                                                                                          |
| avoid (read+write glob) | `page-firewall-alias-edit` / `page-firewall-aliases` | Firewall: Alias                                                                                | `api/firewall/alias/*` includes add/set/del — needs read-only care                                                |
| avoid (read+write glob) | `page-filter-api`                                    | Firewall: Rules [new]                                                                          | `api/firewall/filter/*` includes writes                                                                           |
| avoid                   | `page-status-services`-style                         | Status: Services                                                                               | `api/core/service/*` can start/stop                                                                               |
| **backstop**            | `user-config-readonly`                               | **System: Deny config write**                                                                  | blocks MVC config saves — incomplete (bypasses in GHSA-vw8q-pqq7-2q7v, GHSA-p9pr-782r-w2xw), may be removed later |

Rule of thumb: a privilege whose `api/.../*` glob covers both `search/get` and
`add/set/del` commands grants write too. For a strict read-only key prefer
`page-diagnostics-*` and `page-status-*` picks, and always add
`user-config-readonly` as defense-in-depth.
