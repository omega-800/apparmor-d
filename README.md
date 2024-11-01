# apparmor-d

## Motivation

Apparmor support on NixOS is already available. Although without rules, unconfined programs can still run freely. Luckily, a community-maintained repo named [apparmor.d](https://github.com/roddhjav/apparmor.d) provides thousands of profiles for various programs. The goal of this project is to port all of those profiles to the Nix package manager and provide a module for easy NixOS integration. 
Although [the people at apparmor.d](https://github.com/roddhjav/apparmor.d/graphs/contributors) designed their profiles [with compatibility in mind](https://apparmor.pujol.io/development/#rule-distribution-and-devices-agnostic), integration thereof into Nix proved to be not as easy due to the (reasonable) assumptions of a [FHS](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard). More info on this topic can be found in the [links](#useful-resources) (2, 3) down below.
As this repo is still WIP and not all profiles, architectures or nixpkgs versions have been tested yet, use it **at your own risk**. 

## Usage

Include this repo in `flake.nix`:

```nix
  inputs.apparmor-d.url = "github:omega-800/apparmor-d";
  inputs.apparmor-d.inputs.nixpkgs.follows = "nixpkgs";
```

Configure apparmor-d in `configuration.nix`:

```nix
  security.apparmor-d = {
    enable = true;
    # "disable" to only include profiles in `options.security.apparmor-d.profiles'
    # "enforce" or "complain" to auto-enable profiles in apparmor.d and set them to enforce or complain respectively
    status = "disable";
    profiles = {
      # profileName = "status";
      # profileName must be available in the apparmor.d repo
      # status must be one of "disable", "complain" or "enforce"
      whoami = "enforce";
      firefox = "complain";
    };
  };
```

## Special thanks 

[roddhjav](https://github.com/roddhjav), creator of [apparmor.d](https://github.com/roddhjav/apparmor.d)
[LordGrimmauld](https://github.com/LordGrimmauld), creator of [aa-alias-manager](https://github.com/LordGrimmauld/aa-alias-manager)

## Useful Resources 

1. [apparmor.d documentation](https://apparmor.pujol.io)
2. [AppArmor and apparmor.d on NixOS](https://hedgedoc.grimmauld.de/s/hWcvJEniW#)
3. [The Glob is dead, long live the alias! - AppArmor on NixOS Part 2](https://hedgedoc.grimmauld.de/s/03eJUe0X3#)
4. [openSUSE AppArmor documentation](https://documentation.suse.com/en-us/sles/12-SP5/html/SLES-all/part-apparmor.html)
