# iac

## Table of Contents

- [About and Disclaimer](#about-and-disclaimer)
- [Steps](#steps)
- [Vault Commands](#vault-commands)
- [Author](#author)
- [License](#license)

## About and Disclaimer

This repository is merely for personal use. It's not private since someone might
find it useful and, even for me, it saves the pain of login while in a strangers
computer.

The purpose of this reposity is when I start a freshly Linux image, I can
configure it with all appropriate applications and UI. If you want to use it, do
it at your own risk.

## Steps

_You may [change your user](./group_vars/all/vars.yml) for your specific needs._

1. Install [Python3](https://www.python.org/)

   ```bash
   sudo apt-get install python3 python3-pip git -y
   ```

2. Install Ansible

   ```bash --target
   python3 -m pip install --user ansible-core
   ```

3. Navigate to a place of your choice

   ```bash
   cd $HOME/Documents/guergeiro
   ```

4. Clone the my Infrastructure as Code
   [repository](https://github.com/guergeiro/iac)

   ```bash
   git clone https://github.com/Guergeiro/iac.git
   ```

5. Install playbook dependencies

   ```bash
   ansible-galaxy install -r requirements.yml --force
   ```

6. Run the playbook you want

   ```bash
   ansible-playbook linux-desktop.yml --ask-vault-password --ask-become-pass \
       --vault-id @prompt
   ```

   ```bash
   ansible-playbook linux-wsl.yml --ask-vault-password --ask-become-pass \
       --vault-id @prompt
   ```

   ```bash
   ansible-playbook lisbon.yml --ask-vault-password --ask-become-pass \
       --vault-id @prompt
   ```

## Vault Commands

_More info
[here](https://www.golinuxcloud.com/ansible-vault-example-encrypt-string-playbook/)._

- Create encrypted files

  ```bash
  ansible-vault create secret.yml
  ```

- Edit encrypted files

  ```bash
  ansible-vault edit secret.yml
  ```

- Encrypt existing files

  ```bash
  ansible-vault encrypt file1.yml file2.yml file3.yml
  ```

- Decrypt existing file

  ```bash
  ansible-vault encrypt file1.yml
  ```

- Change password of encrypted file

  ```bash
  ansible-vault rekey encrypted_file.yml
  ```

## Author

Created by [Breno Salles](https://brenosalles.com).

## License

This repository is licensed under [GPL-3.0](./LICENSE).
