{
  extraPythonPackages = p: [ p.regex ];
  testScript = # python
    ''
      import re
      machine.wait_for_unit("default.target")
      # result = machine.succeed("aa-status")
      result = machine.succeed("journalctl -u apparmor")
      if "ERROR" in result:
        profiles = ", ".join(re.findall(r'ERROR.*profile (.*),', result))
        raise Exception("Error loading profile(s): " + profiles)
    '';
}
