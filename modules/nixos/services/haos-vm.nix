{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.haos-vm;
  stateDir = "/var/lib/haos";
  runtimeDir = "/run/haos";
  isCloudHypervisor = cfg.hypervisor == "cloud-hypervisor";
  image = pkgs.fetchurl {
    url = "https://github.com/home-assistant/operating-system/releases/download/18.4/haos_generic-aarch64-18.4.img.xz";
    sha256 = "16580d8baad9eae15e6e912a044526bed885cb8037cd0d426946bc03e1c0267b";
  };
  firmware = pkgs.fetchurl {
    url = "https://github.com/cloud-hypervisor/edk2/releases/download/ch-97eeb7b09/CLOUDHV_EFI.fd";
    sha256 = "13cf4eddc44f3fac4e223b54bcf958de99539297fee8b61cca2605ab5b5009fb";
  };
in
{
  options.services.haos-vm = {
    enable = lib.mkEnableOption "the experimental AArch64 HAOS VM";
    hypervisor = lib.mkOption {
      type = lib.types.enum [
        "qemu"
        "cloud-hypervisor"
      ];
      default = "qemu";
      description = "Hypervisor backend. Cloud Hypervisor requires a GICv3 host.";
    };
    gicVersion = lib.mkOption {
      type = lib.types.enum [
        2
        3
      ];
      default = 3;
      description = "Host-compatible virtual interrupt controller version. Pi 5 requires 2.";
    };
    bridge = lib.mkOption {
      type = lib.types.str;
      description = "Existing Ethernet bridge for the HAOS TAP interface.";
    };
    macAddress = lib.mkOption {
      type = lib.types.str;
      description = "Stable MAC address for the HAOS guest.";
    };
    memoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4096;
      description = "Fixed guest memory allocation in MiB.";
    };
    vcpus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = "Number of guest virtual CPUs.";
    };
    diskSizeGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 32;
      description = "Virtual disk size at initial creation. Existing disks are preserved.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "aarch64-linux";
        message = "services.haos-vm requires an AArch64 Linux host.";
      }
      {
        assertion = cfg.diskSizeGiB >= 32;
        message = "HAOS requires a virtual disk of at least 32 GiB for this deployment.";
      }
      {
        assertion = !isCloudHypervisor || cfg.gicVersion == 3;
        message = "Cloud Hypervisor requires GICv3; the Pi 5 has GICv2. Use QEMU on this host.";
      }
    ];
    users.groups.haos = { };
    users.users.haos = {
      isSystemUser = true;
      group = "haos";
      extraGroups = [ "kvm" ];
    };
    boot.kernelModules = [ "tun" ];

    systemd.network = {
      enable = true;
      netdevs."30-haos-tap" = {
        netdevConfig = {
          Kind = "tap";
          Name = "haos0";
        };
        tapConfig = {
          User = "haos";
          Group = "haos";
        };
      };
      networks."40-haos-tap" = {
        matchConfig.Name = "haos0";
        networkConfig = {
          Bridge = cfg.bridge;
          LinkLocalAddressing = "no";
          ConfigureWithoutCarrier = true;
        };
        linkConfig.RequiredForOnline = false;
      };
    };

    systemd.services.haos = {
      description = "Home Assistant OS (${cfg.hypervisor} guest)";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "systemd-networkd.service"
      ];
      path = [
        pkgs.coreutils
        pkgs.iproute2
        pkgs.xz
        pkgs.gnugrep
      ];
      preStart = ''
        set -eu
        test -r /dev/kvm && test -w /dev/kvm
        for attempt in $(seq 1 60); do
          if ip link show haos0 master ${lib.escapeShellArg cfg.bridge} | grep -q haos0; then
            break
          fi
          sleep 1
        done
        ip link show haos0 master ${lib.escapeShellArg cfg.bridge} | grep -q haos0
        if [ ! -e ${stateDir}/disk.raw ]; then
          trap 'rm -f ${stateDir}/disk.raw.tmp' EXIT
          xz --decompress --stdout ${image} > ${stateDir}/disk.raw.tmp
          truncate -s ${toString cfg.diskSizeGiB}G ${stateDir}/disk.raw.tmp
          mv ${stateDir}/disk.raw.tmp ${stateDir}/disk.raw
          trap - EXIT
        fi
        rm -f ${runtimeDir}/api.sock
      ''
      + lib.optionalString (!isCloudHypervisor) ''
        if [ ! -e ${stateDir}/uefi-vars.fd ]; then
          cp ${pkgs.OVMF.fd}/FV/AAVMF_VARS.fd ${stateDir}/uefi-vars.fd.tmp
          chmod 600 ${stateDir}/uefi-vars.fd.tmp
          mv ${stateDir}/uefi-vars.fd.tmp ${stateDir}/uefi-vars.fd
        fi
      '';
      serviceConfig = {
        User = "haos";
        Group = "haos";
        SupplementaryGroups = [ "kvm" ];
        StateDirectory = "haos";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "haos";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ExecStart = lib.escapeShellArgs (
          if isCloudHypervisor then
            [
              "${pkgs.cloud-hypervisor}/bin/cloud-hypervisor"
              "--firmware"
              "${firmware}"
              "--disk"
              "path=${stateDir}/disk.raw,image_type=raw"
              "--cpus"
              "boot=${toString cfg.vcpus}"
              "--memory"
              "size=${toString cfg.memoryMiB}M"
              "--net"
              "tap=haos0,mac=${cfg.macAddress}"
              "--serial"
              "file=${stateDir}/serial.log"
              "--console"
              "off"
              "--api-socket"
              "${runtimeDir}/api.sock"
            ]
          else
            [
              "${pkgs.qemu_kvm}/bin/qemu-system-aarch64"
              "-name"
              "haos"
              "-machine"
              "virt,accel=kvm,gic-version=${toString cfg.gicVersion}"
              "-cpu"
              "host"
              "-smp"
              (toString cfg.vcpus)
              "-m"
              (toString cfg.memoryMiB)
              "-drive"
              "if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/AAVMF_CODE.fd"
              "-drive"
              "if=pflash,format=raw,file=${stateDir}/uefi-vars.fd"
              "-drive"
              "if=none,id=haos,format=raw,file=${stateDir}/disk.raw,discard=unmap"
              "-device"
              "virtio-blk-pci,drive=haos,bootindex=1"
              "-netdev"
              "tap,id=lan,ifname=haos0,script=no,downscript=no"
              "-device"
              "virtio-net-pci,netdev=lan,mac=${cfg.macAddress}"
              "-device"
              "virtio-rng-pci"
              "-display"
              "none"
              "-serial"
              "file:${stateDir}/serial.log"
              "-monitor"
              "none"
              "-qmp"
              "unix:${runtimeDir}/api.sock,server=on,wait=off"
            ]
        );
        ExecStop = pkgs.writeShellScript "haos-stop" ''
          set -eu
          ${
            if isCloudHypervisor then
              "${pkgs.cloud-hypervisor}/bin/ch-remote --api-socket ${runtimeDir}/api.sock power-button"
            else
              "${pkgs.python3}/bin/python3 ${./haos-qmp-powerdown.py} ${runtimeDir}/api.sock"
          }
          while kill -0 "$MAINPID" 2>/dev/null; do
            ${pkgs.coreutils}/bin/sleep 1
          done
        '';
        TimeoutStartSec = 300;
        TimeoutStopSec = 120;
        Restart = "on-failure";
        RestartSec = 10;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      };
    };
  };
}
