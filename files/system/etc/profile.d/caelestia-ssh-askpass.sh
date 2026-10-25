# KDE: route ssh/ssh-add passphrase prompts through ksshaskpass + KWallet
if [ -n "${KDE_FULL_SESSION:-}${XDG_CURRENT_DESKTOP:-}" ] && command -v ksshaskpass >/dev/null 2>&1; then
    export SSH_ASKPASS=/usr/bin/ksshaskpass
    export SSH_ASKPASS_REQUIRE=prefer
fi
