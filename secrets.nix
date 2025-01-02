let
  ssh-keys = import ./ssh-keys.nix;

  users = ssh-keys.users;
  systems = ssh-keys.systems;
  roles = ssh-keys.roles;

  all-users = ssh-keys.all-users;
  all-systems = ssh-keys.all-systems;

  all = ssh-keys.all;
in {
  # Hashed user passwords
  "secrets/passwords/root.age".publicKeys = all;
  "secrets/passwords/cofob.age".publicKeys = all;

  # Credentials
  # Tailscale
  "secrets/credentials/tailscale/authkey.age".publicKeys = all;
  # Proxmox Backup
  "secrets/credentials/proxmox-backup/key.age".publicKeys = all;
  "secrets/credentials/proxmox-backup/env.age".publicKeys = all;
  # Cloudflare ACME DNS
  "secrets/credentials/cloudflare/api-token.age".publicKeys = all;

  # Loki
  # Read password (for Nginx)
  "secrets/credentials/loki/nginx-read.age".publicKeys = all-users
    ++ roles.monitoring;
  # Read password
  "secrets/credentials/loki/read-password.age".publicKeys = all-users
    ++ roles.monitoring;
  # Write password (for Nginx)
  "secrets/credentials/loki/nginx-write.age".publicKeys = all-users
    ++ roles.monitoring;
  # Write password
  "secrets/credentials/loki/write-password.age".publicKeys = all;
  # Config variables
  "secrets/credentials/loki/variables.age".publicKeys = all-users
    ++ roles.monitoring;

  # AlertManager
  # Telegram token
  "secrets/credentials/alertmanager/telegram-token.age".publicKeys = all-users
    ++ roles.monitoring;
  # Read password (for Nginx)
  "secrets/credentials/alertmanager/nginx-read.age".publicKeys = all-users
    ++ roles.monitoring;
  # Read password
  "secrets/credentials/alertmanager/read-password.age".publicKeys = all-users
    ++ roles.monitoring;

  # Prometheus
  # Read password (for Nginx)
  "secrets/credentials/prometheus/nginx-read.age".publicKeys = all-users
    ++ roles.monitoring;
  # Read password
  "secrets/credentials/prometheus/read-password.age".publicKeys = all-users
    ++ roles.monitoring;
  # Write password (for Nginx)
  "secrets/credentials/prometheus/nginx-write.age".publicKeys = all-users
    ++ roles.monitoring;
  # Write password
  "secrets/credentials/prometheus/write-password.age".publicKeys = all-users
    ++ roles.monitoring;

  # Cloudflare Tailscale DNS sync
  "secrets/credentials/cf-ts-dnssync.age".publicKeys = all-users
    ++ systems.services;
}
