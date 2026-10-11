#!/bin/bash
set -euo pipefail

readonly kernel_args="nvme_core.default_ps_max_latency_us=0 pcie_aspm=off"
readonly grub_defaults=/etc/default/grub
grub_update_command=()
temporary_config=""

fail() {
  echo "Error: $*" >&2
  exit 1
}

detect_grub_update_command() {
  local command config

  if command -v update-grub >/dev/null 2>&1; then
    grub_update_command=(update-grub)
    return
  fi

  for command in grub2-mkconfig grub-mkconfig; do
    if ! command -v "$command" >/dev/null 2>&1; then
      continue
    fi

    for config in /boot/grub2/grub.cfg /boot/grub/grub.cfg; do
      if [[ -f "$config" ]]; then
        grub_update_command=("$command" -o "$config")
        return
      fi
    done
  done

  fail "No supported GRUB update command/configuration found. Install grubby or configure the kernel arguments manually."
}

update_grub_defaults() {
  local line value quote comment argument found=false
  local assignment='^[[:space:]]*GRUB_CMDLINE_LINUX_DEFAULT[[:space:]]*='
  local quoted_value="^[[:space:]]*([\"'])(.*)([\"'])[[:space:]]*(#.*)?$"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ $assignment ]]; then
      value=${line#*=}
      if [[ ! "$value" =~ $quoted_value ]]; then
        echo "Error: Expected a quoted, single-line GRUB_CMDLINE_LINUX_DEFAULT assignment." >&2
        return 1
      fi

      quote=${BASH_REMATCH[1]}
      value=${BASH_REMATCH[2]}
      comment=${BASH_REMATCH[4]:-}
      if [[ "$quote" != "${BASH_REMATCH[3]}" ]]; then
        echo "Error: Mismatched quotes in GRUB_CMDLINE_LINUX_DEFAULT." >&2
        return 1
      fi

      for argument in $kernel_args; do
        if [[ ! " $value " =~ [[:space:]]${argument//./\\.}[[:space:]] ]]; then
          value="${value:+$value }$argument"
        fi
      done

      # Preserve the quote style and comment without evaluating shell code.
      line="${line%%=*}=$quote$value$quote${comment:+ $comment}"
      found=true
    fi
    printf '%s\n' "$line"
  done < "$grub_defaults"

  if [[ "$found" == false ]]; then
    printf 'GRUB_CMDLINE_LINUX_DEFAULT="%s"\n' "$kernel_args"
  fi
}

apply_grub_fallback() {
  [[ -f "$grub_defaults" ]] || fail "$grub_defaults was not found. Install grubby or configure the kernel arguments manually."
  detect_grub_update_command

  temporary_config=$(mktemp)
  trap 'rm -f -- "$temporary_config"' EXIT

  update_grub_defaults > "$temporary_config" || fail "Could not update GRUB defaults."
  sudo tee "$grub_defaults" < "$temporary_config" >/dev/null
  sudo "${grub_update_command[@]}"
}

main() {
  if command -v grubby >/dev/null 2>&1; then
    sudo grubby --update-kernel=ALL --args="$kernel_args"
  else
    apply_grub_fallback
  fi

  echo "Kernel parameters added. Restart the notebook for the change to take effect."
}

main
