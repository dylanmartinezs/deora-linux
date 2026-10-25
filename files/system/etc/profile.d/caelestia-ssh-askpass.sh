# ssh-agent.service (openssh-clients) listens on a fixed path; export it to the session
SSH_AGENT_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"
if [ -z "${SSH_AUTH_SOCK:-}" ] && [ -S "$SSH_AGENT_SOCK" ]; then
    export SSH_AUTH_SOCK="$SSH_AGENT_SOCK"
fi

if command -v ksshaskpass >/dev/null 2>&1; then
    export SSH_ASKPASS=/usr/bin/ksshaskpass
    export SSH_ASKPASS_REQUIRE=prefer
fi
