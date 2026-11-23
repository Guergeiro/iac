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
      sshCommand = "${pkgs.openssh}/bin/ssh -i ${config.age.secrets.ssh_host_ed25519_key.path} -o 'StrictHostKeyChecking=no'";
      storagebox = "u722544@u722544.your-storagebox.de";
      backupDir = "/home/backups/orange/homeassistant";
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
        ];
        encryption = {
          mode = "repokey";
          passCommand = "${pkgs.coreutils}/bin/cat ${config.age.secrets.backups_passphrase.path}";
        };
        environment = {
          BORG_RSH = "${sshCommand}";
        };
        paths = "/root/homeassistant";
        doInit = true;
        startAt = "*-*-* 04:40:00";
        persistentTimer = true;
        preHook = ''
          ${pkgs.systemd}/bin/systemctl stop docker-homeassistant-root.target
          ${sshCommand} -p23 ${storagebox} "mkdir -p ${backupDir}"
        '';
        repo = "ssh://${storagebox}:23${backupDir}";
      };
    };
}
