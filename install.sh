#!/usr/bin/env bash
# One-shot setup: curl -fsSL https://raw.githubusercontent.com/Darkosxl/omarchy-printer/main/install.sh | bash
set -euo pipefail

echo "==> Installing printing packages (cups, avahi, nss-mdns, zenity)"
omarchy pkg add cups avahi nss-mdns zenity

echo "==> Enabling cups and avahi"
sudo systemctl enable --now cups.service avahi-daemon.service

# mDNS lookups (needed for .local printers) require nss-mdns in nsswitch.
if ! grep -qE '^hosts:.*mdns' /etc/nsswitch.conf; then
  echo "==> Adding mdns_minimal to /etc/nsswitch.conf"
  sudo sed -i -E 's/^(hosts:.*)(resolve|dns)/\1mdns_minimal [NOTFOUND=return] \2/' /etc/nsswitch.conf
fi

echo "==> Adding the bar widget"
omarchy plugin add https://github.com/Darkosxl/omarchy-printer.git --enable --yes

echo "Done. Click the printer icon in the bar."
