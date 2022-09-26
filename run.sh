#!/bin/sh
ansible-galaxy install -r requirements.yml
ansible-playbook main.yml --ask-vault-password --vault-id @prompt
