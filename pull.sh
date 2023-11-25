#!/bin/ash

# Bootstrap the system to run ansible-pull, run it, and clean up if needed.
#
# Some installs are meant for testing system setup scripts so the following
# arguments trigger various amounts of cleanup of changes made to get ansible 
# running. I'm being lazy here so it has to be the first arguments.
# 
# --purge, --purge-all - Remove everything installed by this script.
# --purge-ansible - Remove the ansible install.
# --purge-git - Remove the git package.
# --purge-python - Remove the python packages (pip and venv).
# 
# Any additional arguments are passed to `ansible-pull` unaltered.
#
# The vault password can be given with the environment variable
# `VAULT_PASSWORD` or as a file named ``vault-password.secret``. The file is
# automatically shredded upon successful completion of the pull process.

set -e

# .local/bin isn't in $PATH by default usually
export PATH="$HOME/.local/bin:$PATH"

PURGE_ALL=false
PURGE_ANSIBLE=false
PURGE_GIT=false
PURGE_PYTHON=false

while [[ -n "$1" ]]; do
	case $1 in
		--purge|--purge-all)
			PURGE_ALL=true
			shift
			;;
		--purge-ansible)
			PURGE_ANSIBLE=true
			shift
			;;
		--purge-git)
			PURGE_GIT=true
			shift
			;;
		--purge-python)
			PURGE_PYTHON=true
			shift
			;;
		*)
			break
			;;
	esac
done

if [[ "$(whoami)" != "root" ]] && ! (which sudo); then
	echo Either run as root or install sudo >2
	exit 1
fi

# If doas isn't installed this prevents errors about doas being missing
if [[ "$(whoami)" == "root" ]]; then
	DOAS=""
else
	DOAS="doas"
fi

$DOAS apk update
$DOAS apk add --no-cache python3 py3-pip git

if $PURGE_ANSIBLE || $PURGE_ALL; then
	python3 -m venv /tmp/ansible-venv
	source /tmp/ansible-venv/bin/activate
	pip3 install ansible
else
	$DOAS apk add py3-pip
	$DOAS pip3 install pipx
	# Wrapping in an ash call because without doas it tries to run the env vars as files.
	$DOAS ash -c 'export PIPX_HOME=/opt/pipx; export PIPX_BIN_DIR=/usr/local/bin; pipx install ansible'
	# pipx isn't installing all the entrypoints in $PATH. This works around that.
	$DOAS ln -sf /opt/pipx/venvs/ansible/bin/ansible* /usr/local/bin/
fi

if [ -n "$VAULT_PASSWORD" ]; then
	echo "$VAULT_PASSWORD" > vault-password.secret
fi

# Install the collection/role dependencies of the playbook
ansible-galaxy collection install devsec.hardening

if [ -f vault-password.secret ]; then
	ansible-pull \
		-U https://git.hax.in.net/haxwithaxe/ansible-alpine-base.git \
		--vault-password-file vault-password.secret \
		$@
else
	ansible-pull -U https://git.hax.in.net/haxwithaxe/ansible-alpine-base.git $@
fi

# If this script created the vault password file then delete it.
if [ -n "$VAULT_PASSWORD" ]; then
	echo Shredding the vault password
	shred -ux vault-password.secret
fi
if $PURGE_ANSIBLE || $PURGE_ALL; then
	echo Purging ansible
	rm -rf /tmp/ansible-venv
	rm -rf /home/*/.ansible
	if which pipx; then
		$DOAS ash -c 'export PIPX_HOME=/opt/pipx; export PIPX_BIN_DIR=/usr/local/bin; pipx uninstall ansible'
	fi
fi
if $PURGE_GIT || $PURGE_ALL; then
	echo Purging git
	$DOAS apk del git
fi
if $PURGE_PYTHON || $PURGE_ALL; then
	echo Purging python
	$DOAS pip uninstall pipx
	$DOAS apk del python3 py3-pip
fi
