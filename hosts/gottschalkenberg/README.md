# Gottschalkenberg

Gottschalkenberg is an 8 GiB Raspberry Pi 5 running NixOS. QEMU/KVM runs an unmodified generic-AArch64 Home Assistant OS image with two vCPUs, 4 GiB RAM, and a 32 GiB sparse disk. Host boot, KVM guest boot, backup restoration, and Core and app updates have passed live validation. HAOS updates and host reboot recovery remain unverified.

Cloud Hypervisor 54.0 requires GICv3 on ARM. The Pi 5's BCM2712 has a GIC-400/GICv2 controller, so the host explicitly selects QEMU with `gic-version=2`. The reusable VM module also offers Cloud Hypervisor for experiments on compatible GICv3 hardware. An assertion rejects selecting Cloud Hypervisor with `gicVersion = 2`.

## Host installation

The host uses the pinned `nixpkgs-pi` and `home-manager-pi` inputs. Existing hosts retain their stable inputs. The `nixos-hardware` Pi 5 profile supplies the kernel and hardware defaults. The generic AArch64 SD-image module supplies Raspberry Pi firmware, U-Boot, extlinux, and the root filesystem. The ext4 root partition expands to fill the SD card on first boot. ZFS support is disabled to avoid an unused out-of-tree kernel module.

The vendor kernel is cross-compiled on x86_64 Linux. Userspace packages use the native AArch64 package set so cached binaries remain available. Uncached ARM build steps and image assembly require an AArch64 Linux builder. A full cross-build also evaluates, but rebuilds substantially more userspace packages.

The image disables the installer's all-hardware initrd selection and early-boot TPM support. Those defaults request drivers absent from the vendor kernel. The Pi hardware profile and standard storage and USB modules remain enabled; the kernel includes the SD controller and ext4 drivers directly.

The bootstrap image was built using the Pi running Raspberry Pi OS Lite, with a single-user Nix installation under `/home/oliver/.nix-profile`. The bootstrap build command was:

```sh
builder_key=$(ssh oliver@192.168.1.180 cat /etc/ssh/ssh_host_ed25519_key.pub | base64 -w0)
nix build .#nixosConfigurations.gottschalkenberg.config.system.build.sdImage \
  --out-link result-gottschalkenberg \
  --builders "ssh://oliver@192.168.1.180?remote-program=/home/oliver/.nix-profile/bin/nix-store aarch64-linux /home/oliver/.ssh/id_ed25519 2 1 - - $builder_key" \
  --builders-use-substitutes --max-jobs 2 --cores 6
ls result-gottschalkenberg/sd-image/
```

The SSH connection must already trust the Pi's host key. The command passes that key to the Nix daemon, which has a separate known-hosts context. The builder address and Nix executable path apply to the temporary Raspberry Pi OS installation, which has been replaced by NixOS. Subsequent remote builds need the NixOS executable path and daemon permissions configured for the builder account. Builds require an available ARM builder and an x86_64 builder for an uncached kernel. The kernel build platform is fixed in the host configuration, independent of the machine evaluating the flake.

Flash the resulting `.img.zst` with an imaging tool that supports zstd, or decompress it first with `zstd -d`. This replaces the current SD-card operating system. The HAOS VM uses its own disk file inside NixOS. No host image is written to an SD card by evaluating or building this flake.

Connect the Pi's built-in Ethernet port to the LAN. The `macb` Ethernet device with permanent MAC address `98:fe:54:4d:d8:eb` is renamed `lan0` and attached to `br0`. The bridge uses the same MAC address. The host obtains an address through DHCP. Wi-Fi is not configured. The VM obtains a separate DHCP lease with MAC address `02:48:41:05:00:01`.

The Raspberry Pi OS bootstrap confirmed a Pi 5 Model B revision 1.1, 8 GiB RAM, the `macb` driver, and `/dev/kvm`. Its EEPROM version is `66f33f7e651cf482a26fb2c931a7587bb14e71db` (2026-05-11), with `BOOT_ORDER=0xf461`. These observations do not establish NixOS boot or HAOS guest compatibility.

SSH accepts the Wildspitz and Bitwarden public keys configured for `oliver`. Password login is disabled. The `oliver` account has passwordless sudo for initial administration. No private keys, Tailscale credentials, or recovered HA data are embedded in the image. Enrol the host in Tailscale after boot:

```sh
ssh oliver@<host-lan-address>
sudo tailscale up --ssh --advertise-tags=tag:server
ls -l /dev/kvm
networkctl status lan0 br0 haos0
```

The host does not use agenix secrets and has no generated SSH host key registered in `secrets.nix`. Register its actual host key before adding encrypted host secrets.

## Guest lifecycle

The `haos` service starts automatically. Its initial image is HAOS 18.4, fetched with a fixed SHA-256 hash. QEMU uses the AAVMF firmware from the pinned Nixpkgs input and preserves its variable store in `/var/lib/haos/uefi-vars.fd`. The service decompresses the initial image to a temporary file, expands it to 32 GiB, and renames it to `/var/lib/haos/disk.raw`. Existing disks are never replaced or resized by the service. HAOS manages subsequent guest updates.

```sh
sudo systemctl status haos
sudo journalctl -u haos -b
sudo tail -f /var/lib/haos/serial.log
sudo systemctl stop haos
sudo systemctl start haos
```

The hypervisor runs as the `haos` system user. It accesses KVM and a networkd-created TAP device without running as root. The API socket is private to the service in `/run/haos`. A normal service stop sends an ACPI power-button event and waits up to 120 seconds before systemd terminates a nonresponsive guest. Serial output is diagnostic data and may be replaced when the hypervisor starts again.

The guest is directly connected to the LAN through `br0`; it is not behind host NAT. Its services have the same LAN exposure as a separate HA appliance. Tailscale on NixOS provides host administration. Accessing the HA frontend remotely additionally requires a proxy, subnet route, or the restored Tailscale app inside HAOS.

Open `http://<guest-lan-address>:8123` after first boot. Upload `home-assistant-full-2026-10-29-recovered.tar` during onboarding. The recovered backup remains on Wildspitz under `/home/oliver/ha-recovery`; it is not part of the flake. The backup passed Supervisor archive and database validation and a live restore, including all three apps. The restored database file matched the backup checksum.

## Deployment validation

On 2026-11-03, the host booted with LAN address `192.168.1.180` and the guest with `192.168.1.181`. Host Tailscale enrollment uses `tag:server`; `ssh oliver@gottschalkenberg` works. The guest's separately authenticated Tailscale app serves `https://homeassistant.tailacfed0.ts.net/`.

Core updated from 2026.10.3 to 2026.10.4 and the Tailscale app from 0.30.4 to 0.30.6. LAN and tailnet HTTP checks recovered after the expected restarts and remained successful during monitoring. Supervisor reported healthy and supported. The restored Raspberry Pi Power Supply Checker integration was removed because the guest cannot access the physical Pi's power-monitoring interface.

The router-advertised NTP server did not respond during host bringup. A runtime override to `84.254.99.155`, the working NTP server used by Wildspitz, synchronized the host clock. This override is not declarative; persistent NTP configuration remains outstanding.

## Experiment acceptance

Before restoring the backup, verify host SSH, host Tailscale, `/dev/kvm`, guest boot, guest DHCP, and the HA onboarding page. Then verify guest reboot from HA, graceful service stop/start, and host reboot with automatic guest startup. The firmware must boot the HAOS disk through its own bootloader; no extracted kernel or initramfs is supplied by NixOS.

After restoration, verify the integrations and recorder history. Before the first HAOS update, stop the guest and copy its disk to separate storage with a sparse-aware tool. Verify an OS update and reboot, since HAOS boot-slot selection is part of the experiment. NixOS generation rollback does not roll back the guest disk or its database. HA backups remain necessary.

QEMU can support USB-device passthrough, but no USB devices are assigned in this configuration. Network radios and Bluetooth proxies can avoid this requirement. Cloud Hypervisor has no ordinary USB-device passthrough in this setup.

On a compatible AArch64 GICv3 host, `services.haos-vm.hypervisor = "cloud-hypervisor"` and `services.haos-vm.gicVersion = 3` select the alternative backend. That backend uses the checksum-pinned ARM UEFI firmware from Cloud Hypervisor EDK2 release `ch-97eeb7b09`. It is not a runnable alternative on the Pi 5. Firmware boot, guest reboot, and HAOS updates require separate validation on that hardware.

microvm.nix is not used: its standard runner supplies a NixOS guest kernel and initramfs. This service instead preserves HAOS's firmware boot path and writable disk. Firecracker's direct-kernel boot model would require additional integration with HAOS updates.

## References

- [NixOS on Raspberry Pi 5](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5)
- [Cloud Hypervisor ARM UEFI boot](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/uefi.md)
- [Cloud Hypervisor 54.0 ARM host requirements](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/v54.0/README.md#prerequisites-for-aarch64)
- [BCM2712 interrupt controller](https://github.com/raspberrypi/linux/blob/rpi-6.18.y/arch/arm64/boot/dts/broadcom/bcm2712.dtsi)
- [HAOS generic AArch64 images](https://contributors.home-assistant.io/os/operating-system/generic/)
