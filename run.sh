#!/bin/sh
ansible-galaxy install -r requirements.yml
ansible-playbook lisbon.yml --ask-vault-password --ask-become-pass --vault-id @prompt
