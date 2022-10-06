#!/bin/bash

function handle_error() {
  if (( $? )) ; then
    echo -e "[\e[31mERROR\e[39m]"
    echo -e >&2 "CAUSE:\n $1"
    exit 1 
  else
    echo -e "[\e[32mOK\e[39m]"
  fi
}

ANSIBLE_FILES_DIR="$(dirname "$0")"
INVENTORY="${1:-${ANSIBLE_FILES_DIR}/inventory.yml}"

echo -n ">> Checking inventory file (${INVENTORY}) exists and is readable... "
[ -r "${INVENTORY}" ]; handle_error "Please check https://github.com/w3f/polkadot-secure-validator/blob/master/GUIDE_ANSIBLE.md#inventory"

echo -n ">> Testing Ansible availability... "
out=$((ansible --version) 2>&1)
handle_error "$out"

echo -n ">> Finding validator hosts... "
out=$((ansible validator -i ${INVENTORY} --list-hosts) 2>/dev/null)
if [[ $out == *"hosts (0)"* ]]; then
  out="No hosts found, exiting..."
  (exit 1)
  handle_error "$out"
else
  echo -e "[\e[32mOK\e[39m]"
  echo "$out"
fi

echo ">> Executing Ansible Playbook..."

ansible-playbook -i ${INVENTORY} ${ANSIBLE_FILES_DIR}/main_update_binary.yml --become --extra-vars "ansible_become_pass='$SUDO_PW'"

echo ">> Done!"
