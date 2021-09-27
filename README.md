# Polkadex Validator Setup

Right now this set of scripts only creates a validator, full node will be added later.

This set of Ansible scripts are ported over from [W3F's Polkadot Validator Setup](https://github.com/w3f/polkadot-validator-setup/) in order to work with Polkadex.
To use the ansible scripts, go to the ansible directory and make an `inventory.yml` based on `inventory.sample` to suit your setup.
Then run `setup.sh` like this:

```
➜  polkadot-validator-setup/ansible ./setup.sh inventory.yml
```

The setup script will take care of the rest, all you need is to provide it with the sudo password of the user you configured in the `inventory.yaml`.

After everything is setup, you can use the simple `control.sh` script provided to control your validator node
