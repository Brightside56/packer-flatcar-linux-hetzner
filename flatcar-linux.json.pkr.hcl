variable "FLATCAR_RELEASE" {
  type    = string
  default = "3139.2.0"
}

variable "HCLOUD_SERVER_TYPE" {
  type    = string
  default = "cx11"
}

variable "HCLOUD_TOKEN" {
  type    = string
  default = ""
}

variable "HCLOUD_REGION" {
  type    = string
  default = "hel1"
}


variable "system-keymap" {
  type    = string
  default = "us"
}

variable "system-locale" {
  type    = string
  default = "en_US.UTF-8"
}

variable "system-timezone" {
  type    = string
  default = "UTC"
}

source "hcloud" "flatcar" {
  image       = "debian-10"
  location    = var.HCLOUD_REGION
  rescue      = "linux64"
  server_type = var.HCLOUD_SERVER_TYPE
  snapshot_labels = {
    "flatcar/iso.release"  = var.FLATCAR_RELEASE
    os-flavor              = "flatcar-linux"
    "packer.io/build.id"   = "{{ build_name }}"
    "packer.io/build.time" = "{{ timestamp }}"
    "packer.io/version"    = "{{ packer_version }}"
  }
  snapshot_name = format("flatcar-linux-%s", var.FLATCAR_RELEASE)
  ssh_username  = "root"
  token         = var.HCLOUD_TOKEN
}

build {

  sources = ["source.hcloud.flatcar"]

  provisioner "file" {
    content     = templatefile("${path.root}/cl-config.yaml", {})
    destination = "/cl-config.yaml"
  }

  provisioner "shell" {
    inline = [
      "curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 https://raw.githubusercontent.com/kinvolk/init/flatcar-master/bin/flatcar-install",
      "chmod +x flatcar-install",
      "apt update -yqq && apt install -yqq gawk",
      "wget https://github.com/flatcar-linux/container-linux-config-transpiler/releases/download/v0.9.3/ct-v0.9.3-x86_64-unknown-linux-gnu -O /usr/bin/ct && chmod +x /usr/bin/ct",
      "ct -in-file /cl-config.yaml -out-file /ignition.json",
      "cat /ignition.json",
      "./flatcar-install -s -V ${var.FLATCAR_RELEASE} -i /ignition.json",
      "mkdir /tmp/oem && mount /dev/sda6 /tmp/oem",
      "echo 'set linux_append=\"$linux_append nameserver=185.12.64.1 flatcar.autologin=tty1\"' > /tmp/oem/grub.cfg",
      "cat /tmp/oem/grub.cfg",
      "umount /tmp/oem"
    ]
  }

  post-processor "manifest" {
  }
}
