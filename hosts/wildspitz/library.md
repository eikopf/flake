# Library Tailscale identity

The `tailscale-library` Quadlet container publishes `svc:grimmory` and
`svc:shelfmark` as `wildspitzli`, tagged `tag:server`. Its identity persists
in `/var/lib/tailscale-library` (root-only). Userspace networking and UDP port
41642 let it coexist with the desktop's Tailscale daemon. Host networking gives
it access to the loopback backends on ports 6060 and 8084; this separates Tailscale
identities, but does not isolate the container from the host network.

## First deployment

1. Run `just switch` locally on Wildspitz. Switching stops the old Serve units
   and clears their mappings from the desktop daemon. Library access through
   Tailscale is interrupted until the new identity is approved.
2. Follow the login URL in `sudo journalctl -fu tailscale-library.service` and
   sign in with an account allowed to assign `tag:server`. Container startup has
   a 60-second authentication deadline and retries automatically. If a login
   attempt expires, use the URL from the next attempt. Login state survives
   container restarts; no auth key is stored in the flake.
3. In the Tailscale admin console, confirm `wildspitzli` has `tag:server`
   and approve it as a host for both existing Services (or use an appropriate
   service auto-approval policy). Keep the existing service access grants and
   HTTPS configuration. See [Tailscale Services](https://tailscale.com/docs/features/tailscale-services).
4. Check registration and open both service URLs from another tailnet device:

   ```sh
   sudo systemctl status tailscale-library tailscale-serve-grimmory tailscale-serve-shelfmark
   sudo podman exec tailscale-library tailscale status
   sudo podman exec tailscale-library tailscale serve status
   sudo tailscale serve status
   ```

   Both Services should appear in the container; neither should remain on the
   desktop daemon. Serve units retry failed registration and follow container
   restarts. To verify recovery after login, restart `tailscale-library.service`
   and check both service URLs again.
5. Once both Services work, reauthenticate the desktop's `wildspitz` identity
   as your user without tags. Merely clearing advertised tags does not restore
   user ownership; see [Tailscale tags](https://tailscale.com/docs/features/tags).
   From a local terminal, reauthenticate while preserving the configured SSH
   and exit-node settings:

   ```sh
   sudo tailscale up --force-reauth --advertise-tags= --ssh --advertise-exit-node
   ```

   If the CLI requests other existing non-default flags, include those too.
   Confirm the desktop is user-owned in the admin console and the container
   remains tagged. The flake retains Tailscale SSH and exit-node advertisement
   on the desktop; check their access policy and exit-node approval after the
   identity change, especially rules that previously depended on `tag:server`.

## Rollback

Before reverting to a system generation that publishes from the desktop,
restore its `tag:server` identity and service-host approvals. Stop the container's
Serve units, switch to the previous generation, and verify both service URLs.
Keep `/var/lib/tailscale-library` if the container identity will be reused.
