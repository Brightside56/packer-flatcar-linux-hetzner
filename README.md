# Prepare flatcar-linux images for Hetzner cloud with Hashicorp Packer

install packer
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
```
set vars
```
export PKR_VAR_HCLOUD_TOKEN=xxx
export PKR_VAR_HCLOUD_SERVER_TYPE=cx11
export PKR_VAR_HCLOUD_REGION=hel1
export PKR_VAR_FLATCAR_RELEASE=3139.2.0
```
build image
```
packer build .
```
set your key to butane config
```
cat <<EOT >> config.yaml
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - "ssh-rsa yourkey your@email"
EOT
```
install ct
```
wget https://github.com/flatcar-linux/container-linux-config-transpiler/releases/download/v0.9.3/ct-v0.9.3-x86_64-unknown-linux-gnu -O /usr/bin/ct && chmod +x /usr/bin/ct
```
transpile butane config into ignition config and use output as user data during instance creation on Hetzner Cloud
```
ct -in-file config.yaml
```
