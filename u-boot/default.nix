{ buildUBoot
, lib
, python
, armTrustedFirmwareRK3399
, fetchpatch
, fetchFromGitLab
, fetchFromGitHub
, externalFirst ? false
}:

let
  pw = id: sha256: fetchpatch {
    inherit sha256;
    name = "${id}.patch";
    url = "https://patchwork.ozlabs.org/patch/${id}/raw/";
  };

  atf = armTrustedFirmwareRK3399.overrideAttrs(oldAttrs: {
    src = fetchFromGitHub {
      owner = "ARM-software";
      repo = "arm-trusted-firmware";
      rev = "9935047b2086faa3bf3ccf0b95a76510eb5a160b";
      sha256 = "1a6pm0nbgm5r3a41nwlkrli90l2blcijb02li7h75xcri6rb7frk";
    };
    version = "2020-06-17";
  });
in
(buildUBoot {
  defconfig = "pinebook-pro-rk3399_defconfig";
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${atf}/bl31.elf";
  filesToInstall = [
    "idbloader.img"
    "u-boot.itb"
    ".config"
  ];

  extraPatches = [

    # Upstream patches
    # ----------------

    # https://patchwork.ozlabs.org/project/uboot/list/?series=182073
    # https://patchwork.ozlabs.org/patch/1305440/
    (pw "1305440" "1w4vvj3la34rsdf5snlvjl9yxnxrybczjz8m73891x1r6lvr1agk")
    # https://patchwork.ozlabs.org/patch/1305441/
    (pw "1305441" "1my6vz2j7dp6k9qdyf4kzyfy2fgvj4bhxq0xnjkdvsasiz7rq2x9")
    # https://patchwork.ozlabs.org/patch/1305442/
    (pw "1305442" "1i5xy3hn5y780h50anlf5c056aaw5lhpfk6fnh708dn59fp59bx2")

    # Dhivael patchset
    # ----------------
    #
    # Origin: https://git.eno.space/pbp-uboot.git/
    # Forward ported to 2020.07

    ./0001-rk3399-light-pinebook-power-and-standby-leds-during-.patch
    ./0002-reduce-pinebook_pro-bootdelay-to-1.patch

    # samueldr's patchset
    # -------------------
    ./0005-HACK-Add-changing-LEDs-signal-at-boot-on-pinebook-pr.patch
  ] ++ lib.optionals (externalFirst) [
    # Origin: https://git.eno.space/pbp-uboot.git/
    # Forward ported to 2020.07
    ./0003-rockchip-move-mmc1-before-mmc0-in-default-boot-order.patch
    ./0004-rockchip-move-usb0-after-mmc1-in-default-boot-order.patch
  ];
})
.overrideAttrs(oldAttrs: {
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    python
  ];

  postPatch = oldAttrs.postPatch + ''
    patchShebangs arch/arm/mach-rockchip/
  '';

  src = fetchFromGitLab {
    domain = "gitlab.denx.de";
    owner = "u-boot";
    repo = "u-boot";
    sha256 = "1yfkxj2dvyzms8py2k3xps6ijlnjsyhc02wk5b0lz4dm1ha7slnb";
    rev = "v2020.07-rc4";
  };
})
