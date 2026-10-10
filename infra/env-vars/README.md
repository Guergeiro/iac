Encrypting and Decrypting tfvars
```
openssl enc -d -aes-256-cbc -pbkdf2 -in {var}.tfvars.enc -out {var}.tfvars
```

```
openssl enc -aes-256-cbc -pbkdf2 -in {var}.tfvars -out {var}.tfvars.enc
```
