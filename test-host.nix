{ modulesPath, pkgs, ... }: {
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  security = {
    apparmor.enable = true;
    apparmor-d = {
      enable = true;
      # statusAll = "complain";
      profiles = { whoami = "enforce"; };
    };
  };

  users.users = {
    alice = {
      isNormalUser = true;
      initialPassword = "test";
      extraGroups = [ "wheel" ];
    };
    root.initialPassword = "test";
  };

  environment.systemPackages = with pkgs; [ lynis vulnix vim ];
  boot.loader.grub.devices = [ "/dev/sda" ];
  system.stateVersion = "24.05";
}
