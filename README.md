ansible-alpine-base
===================

Setup some basic security and automation on new debian based systems.

Requirements
------------

An basic alpine install.

Host Variables
--------------

- extra_packages (list): A list of extra packages to install with apk.
- no_passwords (bool): Disable passwords for root and interactive users for login and ssh.
- required_groups (list): A list of groups to add to the system.
- sshd_allowed_ssh_users_group: The group to allow ssh access to.
- `user.extra_doas` (list): A list of dictionaries of doas entry parts.
  - `action` (str): ``permit`` or ``deny``. This option is always required.
  - `nopass` (bool): Set the ``nopass`` option. Defaults to `false`.
  - `nolog` (bool): Set the ``nolog`` option. Defaults to `false`.
  - `persist` (bool): Set the ``persist`` option. Defaults to `false`.
  - `keepenv` (bool): Set the ``keepenv`` option. Defaults to `false`. 
  - `setenv` (dict): A dictionary of environment variable to set.
  - `as` (str): The target user to change to. Defaults to unset.
  - `cmd` (str): The executable for the command. Defaults to unset.
  - `args` (list): A list of arguments for the command. Defaults to unset. Requires `cmd` to be set to use.
  - `comment` (str): An arbitrary comment. Defaults to unset.
  - `id` (str): A unique identifier to allow rewriting and removing entries. Defaults to unset.
  - `state` (str): If ``present`` then the entry is added. If ``absent`` the entry with the given `id` is removed. Defaults to ``present``.
- user.groups (list): A list of groups to add the user to.
- user.home_dir (str): The user's home directory. 
- user.name (str): The user's name.
- user.password (str): The user's password hash. This should be encrypted with ansible vault. Defaults to `*` (disabled password).
- user.pubkeys (list): A list of ssh pubkeys to add the user's authorize_keys file.
- user.pubkeys_from_github_user (str): A github username to pull pubkeys from.
- user.pubkeys_from_gitlab_user (str): A gitlab.com username to pull pubkeys from.
- user.pubkeys_from_url (list): A list of URLs to pull ssh pubkeys from.
- user.ssh_user (bool): If true add this user to the `sshd_allowed_ssh_users_group` group.
- user.doas_no_password (bool): If true addsan entry in the ``doas.conf`` file allowing all commands with no password.

Dependencies
------------

- devsec.hardening.ssh_hardening

Examples
--------

``host_vars/alice.yml``:
- Passwordless system
- Pull ssh pubkeys from config, github, gitlab, and a random URL

```
---

users:
  - name: "hax"
    home_dir: "/home/hax"
    append_groups: yes
	groups:
	  - docker
    pubkeys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEF8vRlDjhumQQhySJoxBdYyHZT/w/3lg7DZ6EjiBCp root@orthrus"
    pubkeys_from_github_user: haxwithaxe
    pubkeys_from_gitlab_user: haxwithaxe
    pubkeys_from_urls:
      - "https://git.local/haxwithaxe/pubkeys/raw/branch/main/automation"
    ssh_user: yes
    no_password: yes
    sudo_no_password: yes
  - name: "root"
    home_dir: "/root"

required_groups:
  - name: ssh-users
  - name: docker
    gid: 998
    system: yes

no_passwords: yes
sshd_allowed_ssh_users_group: ssh-users
sshd_moduli_size: 2048
sshd_rsa_host_key_size: 8192
```

License
-------

GPLv3

Author Information
------------------

Created by [haxwithaxe](https://github.com/haxwithaxe)
