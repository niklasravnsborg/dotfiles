{
  config,
  pkgs,
  ...
}:

{
  environment.systemPackages = [ pkgs.cloudflared ];

  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = { };

  sops.secrets."cloudflared/injubox" = {
    owner = "cloudflared";
    group = "cloudflared";
  };

  systemd.services.injubox-tunnel = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "systemd-resolved.service"
    ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "injubox-tunnel" ''
        ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run \
          --token $(cat ${config.sops.secrets."cloudflared/injubox".path})
      '';
      Restart = "always";
      User = "cloudflared";
      Group = "cloudflared";
    };
  };

}
