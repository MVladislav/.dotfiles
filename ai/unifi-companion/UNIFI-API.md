# UniFi Network Integration API — reference (v10.4.57)

Source: https://developer.ui.com/network/v10.4.57/llms.txt

Authentication: all APIs use API Key authentication via the `X-API-KEY` header.
Generate keys at unifi.ui.com (Network → Settings → Integrations,
`DOMAIN/network/default/integrations`; fields are only Name/Description/Expiry).

> ⚠️ A key has **no read-only toggle** — it is full-access. Endpoints below
> tagged `(write)` are reachable with any key; a read-only workflow relies on
> the skill using only the `GET` endpoints.

Full contract: https://developer.ui.com/network/v10.4.57/openapi.json

Base path on the console: `{UNIFI_HOST}/proxy/network/integration/v1`

## Application Info

- `GET /v1/info` — Get Application Info

## Sites

- `GET /v1/sites` — List Local Sites

## UniFi Devices

- `GET /v1/pending-devices` — List Devices Pending Adoption
- `GET /v1/sites/{siteId}/devices` — List Adopted Devices
- `POST /v1/sites/{siteId}/devices` — Adopt Devices (write)
- `DELETE /v1/sites/{siteId}/devices/{deviceId}` — Remove (Unadopt) Device (write)
- `GET /v1/sites/{siteId}/devices/{deviceId}` — Get Adopted Device Details
- `POST /v1/sites/{siteId}/devices/{deviceId}/actions` — Execute Device Action (write)
- `POST /v1/sites/{siteId}/devices/{deviceId}/interfaces/ports/{portIdx}/actions` — Port Action (write)
- `GET /v1/sites/{siteId}/devices/{deviceId}/statistics/latest` — Latest Device Statistics

## Clients

- `GET /v1/sites/{siteId}/clients` — List Connected Clients
- `GET /v1/sites/{siteId}/clients/{clientId}` — Get Connected Client Details
- `POST /v1/sites/{siteId}/clients/{clientId}/actions` — Execute Client Action (write)

## Networks

- `GET /v1/sites/{siteId}/networks` — List Networks
- `POST /v1/sites/{siteId}/networks` — Create Network (write)
- `DELETE /v1/sites/{siteId}/networks/{networkId}` — Delete Network (write)
- `GET /v1/sites/{siteId}/networks/{networkId}` — Get Network Details
- `PUT /v1/sites/{siteId}/networks/{networkId}` — Update Network (write)
- `GET /v1/sites/{siteId}/networks/{networkId}/references` — Get Network References

## WiFi Broadcasts

- `GET /v1/sites/{siteId}/wifi/broadcasts` — List Wifi Broadcasts
- `POST /v1/sites/{siteId}/wifi/broadcasts` — Create Wifi Broadcast (write)
- `DELETE /v1/sites/{siteId}/wifi/broadcasts/{wifiBroadcastId}` — Delete (write)
- `GET /v1/sites/{siteId}/wifi/broadcasts/{wifiBroadcastId}` — Get Details
- `PUT /v1/sites/{siteId}/wifi/broadcasts/{wifiBroadcastId}` — Update (write)

## Hotspot

- `DELETE /v1/sites/{siteId}/hotspot/vouchers` — Delete Vouchers (write)
- `GET /v1/sites/{siteId}/hotspot/vouchers` — List Vouchers
- `POST /v1/sites/{siteId}/hotspot/vouchers` — Generate Vouchers (write)
- `DELETE /v1/sites/{siteId}/hotspot/vouchers/{voucherId}` — Delete Voucher (write)
- `GET /v1/sites/{siteId}/hotspot/vouchers/{voucherId}` — Get Voucher Details

## Firewall

- `GET /v1/sites/{siteId}/firewall/policies` — List Firewall Policies
- `POST /v1/sites/{siteId}/firewall/policies` — Create Firewall Policy (write)
- `GET /v1/sites/{siteId}/firewall/policies/ordering` — Get Policy Ordering
- `PUT /v1/sites/{siteId}/firewall/policies/ordering` — Reorder Policies (write)
- `DELETE /v1/sites/{siteId}/firewall/policies/{firewallPolicyId}` — Delete (write)
- `GET /v1/sites/{siteId}/firewall/policies/{firewallPolicyId}` — Get Policy
- `PATCH /v1/sites/{siteId}/firewall/policies/{firewallPolicyId}` — Patch (write)
- `PUT /v1/sites/{siteId}/firewall/policies/{firewallPolicyId}` — Update (write)
- `GET /v1/sites/{siteId}/firewall/zones` — List Firewall Zones
- `POST /v1/sites/{siteId}/firewall/zones` — Create Custom Zone (write)
- `DELETE /v1/sites/{siteId}/firewall/zones/{firewallZoneId}` — Delete Zone (write)
- `GET /v1/sites/{siteId}/firewall/zones/{firewallZoneId}` — Get Zone
- `PUT /v1/sites/{siteId}/firewall/zones/{firewallZoneId}` — Update Zone (write)

## Access Control (ACL Rules)

- `GET /v1/sites/{siteId}/acl-rules` — List ACL Rules
- `POST /v1/sites/{siteId}/acl-rules` — Create ACL Rule (write)
- `GET /v1/sites/{siteId}/acl-rules/ordering` — Get ACL Ordering
- `PUT /v1/sites/{siteId}/acl-rules/ordering` — Reorder ACL Rules (write)
- `DELETE /v1/sites/{siteId}/acl-rules/{aclRuleId}` — Delete ACL Rule (write)
- `GET /v1/sites/{siteId}/acl-rules/{aclRuleId}` — Get ACL Rule
- `PUT /v1/sites/{siteId}/acl-rules/{aclRuleId}` — Update ACL Rule (write)

## Switching

- `GET /v1/sites/{siteId}/switching/lags` — List LAGs
- `GET /v1/sites/{siteId}/switching/lags/{lagId}` — Get LAG Details
- `GET /v1/sites/{siteId}/switching/mc-lag-domains` — List MC-LAG Domains
- `GET /v1/sites/{siteId}/switching/mc-lag-domains/{mcLagDomainId}` — Get MC-LAG Domain
- `GET /v1/sites/{siteId}/switching/switch-stacks` — List Switch Stacks
- `GET /v1/sites/{siteId}/switching/switch-stacks/{switchStackId}` — Get Switch Stack

## DNS Policies

- `GET /v1/sites/{siteId}/dns/policies` — List DNS Policies
- `POST /v1/sites/{siteId}/dns/policies` — Create DNS Policy (write)
- `DELETE /v1/sites/{siteId}/dns/policies/{dnsPolicyId}` — Delete DNS Policy (write)
- `GET /v1/sites/{siteId}/dns/policies/{dnsPolicyId}` — Get DNS Policy
- `PUT /v1/sites/{siteId}/dns/policies/{dnsPolicyId}` — Update DNS Policy (write)

## Traffic Matching Lists

- `GET /v1/sites/{siteId}/traffic-matching-lists` — List Traffic Matching Lists
- `POST /v1/sites/{siteId}/traffic-matching-lists` — Create (write)
- `DELETE /v1/sites/{siteId}/traffic-matching-lists/{trafficMatchingListId}` — Delete (write)
- `GET /v1/sites/{siteId}/traffic-matching-lists/{trafficMatchingListId}` — Get
- `PUT /v1/sites/{siteId}/traffic-matching-lists/{trafficMatchingListId}` — Update (write)

## Supporting Resources

- `GET /v1/countries` — List Countries
- `GET /v1/dpi/applications` — List DPI Applications
- `GET /v1/dpi/categories` — List DPI Application Categories
- `GET /v1/sites/{siteId}/device-tags` — List Device Tags
- `GET /v1/sites/{siteId}/radius/profiles` — List Radius Profiles
- `GET /v1/sites/{siteId}/vpn/servers` — List VPN Servers
- `GET /v1/sites/{siteId}/vpn/site-to-site-tunnels` — List Site-To-Site VPN Tunnels
- `GET /v1/sites/{siteId}/wans` — List WAN Interfaces
