{
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    ./sd-image.nix
    ./ap-configuration.nix
    ./create-ap.nix
    ./nginx.nix
  ];

  networking.hostName = "keiko"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;


  # Some packages (ahci fail... this bypasses that) https://discourse.nixos.org/t/does-pkgs-linuxpackages-rpi3-build-all-required-kernel-modules/42509
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  # ! Need a trusted user for deploy-rs.
  nix.settings.trusted-users = ["@wheel"];
  system.stateVersion = "24.05";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  sdImage = {
    # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low on space.
    compressImage = false;
    imageName = "keiko2w.img";

    extraFirmwareConfig = {
      # Give up VRAM for more Free System Memory
      # - Disable camera which automatically reserves 128MB VRAM
      start_x = 0;
      # - Reduce allocation of VRAM to 16MB minimum for non-rotated (32MB for rotated)
      gpu_mem = 16;

      # Configure display to 800x600 so it fits on most screens
      # * See: https://elinux.org/RPi_Configuration
      hdmi_group = 2;
      hdmi_mode = 8;
    };
  };

  # Keep this to make sure wifi works
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [pkgs.raspberrypiWirelessFirmware];

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi02w;

    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
    # See: https://github.com/NixOS/nixpkgs/issues/254807
    swraid.enable = lib.mkForce false;
  };

  environment.systemPackages = with pkgs; [
    git
    htop
    wget
    curl
    killall
    powertop
    bb
    sl
    elinks
    lsof

    bastet
    nethack
    ninvaders
    nsnake
    nbsdgames
    moon-buggy
    nudoku

    nano
    emacs
    ((vim_configurable.override {  }).customize{
      name = "vim";
      # Install plugins for example for syntax highlighting of nix files
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-nix vim-surround ];
        opt = [];
      };
      vimrcConfig.customRC = ''
        set nocompatible
        " Turn on syntax highlighting by default
        syntax on
        set backspace=indent,eol,start
        set mouse=
        set tabstop=2
        set shiftwidth=2
      '';
    }
    )

    (ponysay.overrideAttrs ( oldAttrs: rec {
      src = pkgs.fetchFromGitHub {
        owner = "Tonyl314";
        repo = "ponysay";
        rev = "f7231e17c137a8600dce2a9c62b65eaed342979e";
        hash = "sha256-xs5blffoht+PolqRf2hPH0TO5U6UacxTf4J5u5/0Nvs=";
      };

      # this double-corrects a bug that tony also fixed, i think
      installPhase = ''
        runHook preInstall

        find -type f -name "*.py" | xargs sed -i "s@/usr/bin/env python3@$python3/bin/python3@g"
        substituteInPlace setup.py --replace \
            "fileout.write(('#!/usr/bin/env %s\n' % env).encode('utf-8'))" \
            "fileout.write(('#!%s/bin/%s\n' % (os.environ['python3'], env)).encode('utf-8'))"

        python3 setup.py --prefix=$out --freedom=partial install \
            --with-shared-cache=$out/share/ponysay \
            --with-bash

        runHook postInstall
      '';
      
      postInstall = (oldAttrs.postInstall or "") + ''
         rm -vf $out/share/ponysay/ponies/{sindy,powderrouge}.pony
         rm -vf $out/share/ponysay/ttyponies/{sindy,powderrouge}.pony
      '';
    }))
  
  ];


  # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;

  users.motd = "\nWelcome to Keiko! Don't forget to sign our guestbook at /var/www/website/index.html \n\n";

  # ! Change the following configuration
  users.users.grace = {
    isNormalUser = true;
    home = "/home/grace";
    description = "Grace";
    extraGroups = ["wheel" "networkmanager"];
    # ! Be sure to put your own public key here
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPYgLe8xPnT4kzEBghYZCjHRQk9eT/7k8ssArIpsgqo"];
    initialHashedPassword = "$y$j9T$9aaXSQ8qJG2PyYJhN1aV10$25gbAZUwj2RUegypQIqhKHz/VGnRoxtBVTNVLMnfEQB";
  };

  users.users.hoshiko = {
    isNormalUser = true;
    home = "/home/hoshiko";
    description = "Mahou Shoujo";
    # ! Be sure to put your own public key here
    #openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPYgLe8xPnT4kzEBghYZCjHRQk9eT/7k8ssArIpsgqo"];
    initialPassword = "fuckweyland";
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  # ! Be sure to change the autologinUser.
  services.getty.autologinUser = "hoshiko";
}
