#!/bin/sh
# Install or upgrade Bilskirnir:
#   curl -fsSL https://raw.githubusercontent.com/drucedev/bilskirnir/main/install.sh | sh
# Clones into the Quickshell config dir, or fast-forwards an existing checkout.
# Dependencies are only checked; install missing ones with your package manager.
set -eu

repo=${BILSKIRNIR_REPO:-https://github.com/drucedev/bilskirnir.git}
dir=${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/bilskirnir

# Ours: $dir is itself a git worktree whose configured origin is this repository.
is_checkout() {
	[ -e "$dir/.git" ] || return 1
	origin=$(git -C "$dir" config --get remote.origin.url) || return 1
	case "$origin" in
	"$repo" | https://github.com/drucedev/bilskirnir | https://github.com/drucedev/bilskirnir.git | \
		git@github.com:drucedev/bilskirnir | git@github.com:drucedev/bilskirnir.git) return 0 ;;
	esac
	return 1
}

if [ ! -e "$dir" ]; then
	mkdir -p "$(dirname "$dir")"
	git clone --quiet --branch main "$repo" "$dir"
	echo "Installed Bilskirnir in $dir"
elif is_checkout; then
	if [ "$(git -C "$dir" symbolic-ref --quiet --short HEAD)" != main ]; then
		echo "error: $dir is not on main; switch to main to upgrade." >&2
		exit 1
	fi
	git -C "$dir" pull --quiet --ff-only origin main
	echo "Updated Bilskirnir in $dir"
else
	echo "error: $dir exists and is not a bilskirnir checkout; move it away first." >&2
	exit 1
fi

for tool in qs nmcli ghostty btop; do
	command -v "$tool" >/dev/null 2>&1 || echo "missing: $tool"
done
font="JetBrainsMono Nerd Font"
# fc-list prints one comma-separated list of family names per font; match a whole name.
fc-list : family 2>/dev/null | grep -qE "(^|,)$font(,|\$)" || echo "missing: $font"

echo "Start it with: qs --no-duplicate -c bilskirnir"
