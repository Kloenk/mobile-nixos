{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, buildPackages
, dtbTool
}:

(mobile-nixos.kernel-builder-gcc6 {
  configfile = ./config.aarch64;

  file = "Image.gz-dtb";
  hasDTB = true;

  version = "3.18.120";
  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_xiaomi_msm8996";
    rev = "995ab94566350a608cbb2bb6ca3fe79299d424c9";
    sha256 = "01j92v9ywrz896rkq91irsiz2iglqyihcr85jsjys4sbb1ks9pdc";
  };

  patches = [
    #./99_framebuffer.patch
    #./0001-Imports-drivers-input-changes-from-lineage-16.0.patch
    #./0001-s3320-Workaround-libinput-claiming-kernel-bug.patch
  ];

  isModular = false;

  makeFlags = [ "DCT_EXT=${buildPackages.dtc}/bin/dtc" ];

}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "Image.gz" "zinstall" "Image.gz-dtb" "install" ];
  postPatch = postPatch + ''
    cp -v "${./compiler-gcc6.h}" "./include/linux/compiler-gcc6.h"

    # FIXME : factor out
    (
    # Remove -Werror from all makefiles
    local i
    local makefiles="$(find . -type f -name Makefile)
    $(find . -type f -name Kbuild)"
    for i in $makefiles; do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror=/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    )
  '';
  postInstall = postInstall + ''
    mkdir -p "$out/dtbs/"
    cp -v "$buildRoot/arch/arm64/boot/Image.gz-dtb" "$out/"
  '';
})
