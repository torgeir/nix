# Migration: Wallabag rootful → rootless podman

The wallabag container used to run under the system-level `podman-wallabag`
service (rootful, via `virtualisation.oci-containers`).  It now runs as a
dedicated `wallabag` system user under the `wallabag.service` systemd unit
(rootless podman).

Perform the steps below **in order** when rolling out this change.

---

## Why rootless?

- The container process never has real root on the host.
- A vulnerability in the container runtime or image cannot escape to host root.
- The data directory is owned by a purpose-specific user, not the catch-all
  `nobody`.

---

## What changed in Nix

| Area | Before | After |
|------|--------|-------|
| Systemd unit | `podman-wallabag.service` (oci-containers) | `wallabag.service` (custom) |
| Runtime user | root | `wallabag` (uid auto-assigned by NixOS) |
| Data dir owner | `nobody:nogroup` | `wallabag:wallabag` |
| Podman network | created by root activation script | created by service user on first start |
| Secret ownership | root | `wallabag` (mode 0400) |
| New package | — | `slirp4netns` (rootless NAT) |

---

## Pre-deployment steps (before `nixos-rebuild switch`)

Run these as root on the server.

### 1. Stop and disable the old rootful service

```sh
systemctl stop podman-wallabag.service
systemctl disable podman-wallabag.service
```

### 2. Remove the old rootful podman network (optional, avoids name clash)

```sh
podman network rm wallabag 2>/dev/null || true
```

---

## Deployment

```sh
nixos-rebuild switch
```

During the switch, the activation script will:

- Create the `wallabag` system user (with `/etc/subuid` and `/etc/subgid`
  entries for rootless user-namespace support).
- Create `/var/lib/wallabag` (home dir for podman storage).
- `chown -R wallabag:wallabag /fast/shared/apps/wallabag/data`.
- Re-deploy the agenix secret at `/run/agenix/wallabag-env` owned by
  `wallabag:wallabag` mode 0400.
- Register and start `wallabag.service`.

---

## Post-deployment verification

```sh
# Service should be active
systemctl status wallabag.service

# Tail logs
journalctl -fu wallabag.service

# Container should be listed (as wallabag user)
sudo -u wallabag XDG_RUNTIME_DIR=/run/wallabag podman ps

# Confirm port is bound
ss -tlnp | grep 8091

# Smoke-test HTTP through nginx
curl -IL https://wallabag.wa.gd
```

---

## Rollback

If something goes wrong:

```sh
# Stop the new service
systemctl stop wallabag.service

# Restore old ownership so the rootful container can write data
chown -R nobody:nogroup /fast/shared/apps/wallabag/data

# Re-enable the rootful service (it will come back after next switch to old config)
git revert HEAD   # on the nix repo
nixos-rebuild switch
```

---

## Notes

- Port binding (8091) works fine for rootless podman because 8091 > 1024.
  Ports ≤ 1024 would require `net.ipv4.ip_unprivileged_port_start` to be
  lowered via `boot.kernel.sysctl`.
- The container's internal network (`wallabag`) is now a per-user rootless
  network, separate from any system-level podman networks.  Other rootful
  containers (immich, freshrss, …) are unaffected.
- `slirp4netns` provides NAT for outbound traffic from rootless containers.
  It is now included in `environment.systemPackages` via `podman.nix`.
