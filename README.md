# vivobook-rtw89_8852be-suspend-fix

Scripts for two suspend/resume issues on the Vivobook:

- Reload the `rtw89_8852be` Wi-Fi driver after resume.
- Disable NVMe power-state latency and PCIe ASPM to prevent freezes and
  unexpected restarts when resuming after a long suspend.


## Running

Execute the command below in the terminal
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/lorenzolpandolfo/vivobook-rtw89_8852be-suspend-fix/main/setup-wifi-fix.sh)"
```

This installs the Wi-Fi resume hook. Your Wi-Fi card should work correctly
after suspend now.

## Long-suspend resume fix

If the notebook freezes or restarts when resuming after being suspended for
hours, install the kernel parameters with:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/lorenzolpandolfo/vivobook-rtw89_8852be-suspend-fix/main/setup-suspend-fix.sh)"
```

The script prefers `grubby` to add these arguments to all installed kernel
entries. If `grubby` is unavailable, it falls back to `/etc/default/grub` and
regenerates the configuration using `update-grub`, or `grub2-mkconfig` /
`grub-mkconfig` when an existing `/boot/grub2/grub.cfg` or
`/boot/grub/grub.cfg` is detected. The fallback uses Bash and preserves
existing arguments without duplicating the added parameters. Systems with
other bootloader setups need to add the arguments using that bootloader's
configuration method.

```text
nvme_core.default_ps_max_latency_us=0 pcie_aspm=off
```

Restart the notebook for the change to take effect, then check that the
arguments are present with:

```bash
cat /proc/cmdline
```
