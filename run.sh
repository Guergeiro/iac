#!/bin/sh

if [ "$1" = "--force" ]; then
  ansible-galaxy install -r requirements.yml --force
else
  ansible-galaxy install -r requirements.yml
fi

ansible-playbook lisbon.yml --ask-vault-password --ask-become-pass --vault-id @prompt
