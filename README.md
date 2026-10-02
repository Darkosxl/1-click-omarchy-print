# omarchy-printer

An [Omarchy](https://omarchy.org) top-bar button. Click it for a popup panel: pick a printer, pick a PDF (recent ones listed, or Browse…), press Print.

Printers come from CUPS, so anything CUPS sees shows up: network printers
discovered over mDNS/DNS-SD (AirPrint / IPP Everywhere) via Avahi, USB printers,
and manually added queues.

## Requirements

```bash
omarchy pkg add cups avahi nss-mdns zenity
sudo systemctl enable --now cups.service avahi-daemon.service
```

On Arch, `nss-mdns` must be in the `hosts:` line of `/etc/nsswitch.conf`
(`mdns_minimal [NOTFOUND=return]` before `resolve`/`dns`). See the
[Arch wiki](https://wiki.archlinux.org/title/CUPS#Network).

## Install

```bash
omarchy plugin add https://github.com/<your-user>/omarchy-printer.git --enable
```

Move it with `omarchy bar move darkosxl.printer --section right`.

## Use

Click the printer icon. Printers are discovered automatically (the list refreshes every 15 s while open; `r` refreshes now). The default printer is preselected and marked ★. Recent PDFs from `~/Downloads`, `~/Documents` and `~/Desktop` are listed; `Browse…` opens a file picker. `Enter` prints, `Esc` closes.

## Troubleshooting

| Problem | Check |
|---|---|
| "No printers found" | `lpstat -e`, `lpinfo -v`, both services running |
| Network printer missing | `avahi-browse -art`, same subnet/VLAN as the printer, mDNS not blocked |
| Add a printer by hand | `lpadmin -p Name -E -v ipp://IP/ipp/print -m everywhere` |

Bluetooth printers are not auto-discovered by CUPS; pair and add the queue manually.

## License

MIT
