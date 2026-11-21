{ inputs, ... }:
{
  flake.nixosModules."orange-borgbackup" =
    {
      pkgs,
      config,
      hostname,
      ...
    }:
    let
      sshCommand = "${pkgs.openssh}/bin/ssh -p 23 -i ${config.age.secrets.ssh_host_ed25519_key.path}";
      storagebox = "u722544@u722544.your-storagebox.de";
    in
    {
      age.secrets."backups_passphrase".file = "${inputs.nix-secrets}/backups_passphrase.age";

      services.borgbackup.jobs."${hostname}-homeassistant" = {
        prune.keep = {
          # Keeps gfs 7 daily, 4 weekly, 3 monthly
          daily = 7;
          weekly = 4;
          monthly = 3;
        };
        extraArgs = [
          "--remote-path=borg-1.4"
        ];
        extraCreateArgs = [
          "--stats"
          "--checkpoint-interval 600"
        ];
        encryption = {
          mode = "repokey";
          passCommand = "${pkgs.coreutils}/bin/cat ${config.age.secrets.backups_passphrase.path}";
        };
        environment = {
          BORG_RSH = "${sshCommand}";
        };
        paths = [
          "/root/homeassistant"
        ];
        startAt = "*-*-* 04:45:00";
        persistentTimer = true;
        preHook = ''
          ${sshCommand} ${storagebox} "mkdir -p /home/backups/orange/homeassistant"
        '';
        repo = "ssh://${storagebox}:23/home/backups/orange/homeassistant";
      };
    };
}
