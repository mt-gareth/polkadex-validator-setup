# Ansible Guide

This repo contains collections of Ansible scripts inside the [ansible/](ansible)
directory, so called "Roles", which are responsible for the provisioning of
all configured nodes. It automatically sets up the [Application
Layer](README.md/#application-layer) and manages updates for Polkadex
software releases.

There is a main Ansible Playbook that orchestrates all the roles, it gets
executed locally on your machine, then connects to the configured nodes and sets
up the required tooling. Firewalls, Polkadex nodes and all its dependencies are
installed by issuing a single command. No manual intervention into the remote
nodes is required.

## Prerequisites

* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
  (v2.8+)

  On Debian-based systems this can be installed with `sudo apt install ansible`
  from the standard repositories.

* Running Debian-based nodes

  The nodes require configured SSH access, but don't need any other preparatory
  work. It's up to you on how many nodes you want to use. This setup assumes the
  remote users have `sudo` privileges with the same `sudo` password.
  Alternatively, [additional
  configuration](https://docs.ansible.com/ansible/latest/user_guide/become.html)
  is required.

It's recommended to setup SSH pubkey authentication for the nodes and to add the
access keys to the SSH agent.

## Inventory

All required data is saved in a [Ansible
inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html),
which by default is placed under `/etc/ansible/hosts` (but you can create it
anywhere you want) and must only be configured once. Most values from the
[SAMPLE FILE](ansible/inventory.sample) can be copied. Only a handful of entries
must be adjusted.

For each node, the following information must be configured in the Ansible
inventory:

* IP address or URL.
* SSH user (as `ansible_user`). It's encouraged NOT to use `root`.
* (optional) The telemetry URL (e.g. `wss://telemetry.polkadex.io/submit/`,
  where the info can then be seen under https://telemetry.polkadex.io).
* (optional) The logging filter.

The other default values from the sample inventory can be left as is.

**NOTE**: Telemetry information exposes IP address, among other information. For
this reason it's highly encouraged to use a [private telemetry
server](https://github.com/paritytech/substrate-telemetry) and not to expose the
validator to a public server.

### Setup Validator

Setup the validator node by specifying a `[validator_<NUM>]` host, including its
required variables. `<NUM>` should start at `0` and increment for each other
validator (assuming you have more than one validator).

Example:

```ini
[validator_0]
147.75.76.65

[validator_0:vars]
ansible_user=alice

[validator_1]
162.12.35.55

[validator_1:vars]
ansible_user=bob
```

### Grouping Validators

All nodes to be setup must be grouped under `[validator:children]`.

Example:

```ini
[validator:children]
validator_0
validator_1
```

### Specify common variables

Finally, define the common variables for all the nodes.

Important variables which should vary from the [sample inventory](ansible/inventory.sample):

* `project` - The name for how each node should be prefixed for the telemetry
  name.
* `polkadex_binary_url` - This is the URL from were Ansible will
  download the Polkadex binary.
* `polkadex_binary_checksum` - The SHA256 checksum of the Polkadex binary which
  Ansible verifies during execution. Must be prefixed with `sha256:`.
* `node_exporter_enabled` - Enable or disable the setup of [Node
  Exporter](https://github.com/prometheus/node_exporter). It's up to you whether
  you want it or not.

The other default values from the sample inventory can be left as is.

Example:

```ini
[all:vars]
# The name for how each node should be prefixed for the telemetry name
project=alice-in-wonderland

# Can be left as is.
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=15'
build_dir=$HOME/.config/polkadex-secure-validator/build/w3f/ansible

# Specify which `polkadex` binary to install. Checksum is verified during execution.
polkadex_binary_url='https://github.com/Polkadex-Substrate/Polkadex/releases/latest/download/PolkadexNodeUbuntu.zip'
polkadex_binary_checksum='sha256:9a6104b019638dfb0d1e7091a7247555afb5ebc1f449829a5536a128563d5f56

# Nginx authentication settings.
nginx_user='prometheus'
nginx_password='nginx_password'

# Node exporter settings. Disabled by default.
node_exporter_enabled='false'
node_exporter_binary_url='https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz'
node_exporter_binary_checksum='sha256:b2503fd932f85f4e5baf161268854bf5d22001869b84f00fd2d1f57b51b72424'

# Polkadex service restart settings. Enabled to restart every hour.
polkadex_restart_enabled='true'
polkadex_restart_minute='0'
polkadex_restart_hour='*'
polkadex_restart_day='*'
polkadex_restart_month='*'
polkadex_restart_weekday='*'

```

## Execution

```console
user@pc:~$ cd polkadex-secure-validator/ansible
```

Once the inventory file is configured, simply run the setup script and specify
the `sudo` password for the remote machines.

**NOTE**: If no inventory path is specified, it will try to look for
`ansible/inventory.yml` by default.

```console
user@pc:~/polkadex-secure-validator/ansible$ chmod +x setup.sh
user@pc:~/polkadex-secure-validator/ansible$ ./setup.sh my_inventory.yml
Sudo password for remote servers:
>> Pulling upstream changes... [OK]
>> Testing Ansible availability... [OK]
>> Finding validator hosts... [OK]
  hosts (2):
    147.75.76.65
    162.12.35.55
>> Testing connectivity to hosts... [OK]
>> Executing Ansible Playbook...

...
```

Alternatively, execute the Playbook manually ("become" implies `sudo`
privileges).

```console
user@pc:~/polkadex-secure-validator/ansible$ ansible-playbook -i my_inventory.yml main.yml --become --ask-become
```

The `setup.sh` script handles some extra functionality, such as downloading the
newest upstream changes and checking connectivity of remote hosts including
privilege escalation. This script/Playbook can be executed over and over again.

Additional Playbooks are provided besides `main.yml`, but those are outside the
scope of this guide.

### Updating Polkadex

To update the Polkadex version, simply adjust those two lines in the Ansible
inventory:

```ini
polkadex_binary_url='...'
polkadex_binary_checksum='sha256:...'
```

Then just execute `setup.sh` again.
