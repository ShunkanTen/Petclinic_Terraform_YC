terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.99.1"
}

provider "yandex" {
  zone      = "ru-central1-a"
  folder_id = "b1g1qiql9fvto0ppnms0"
  cloud_id  = "b1gjjgb4685d1vakrjeq"
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_security_group" "external_connection_with_petclinic" {
  name        = "security croup"
  description = "security group for petclinic"
  network_id  = yandex_vpc_network.network-1.id
  ingress {
    protocol       = "TCP"
    description    = "ssh connection rules"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  ingress {
    protocol       = "TCP"
    description    = "protocol HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
  ingress {
    protocol       = "TCP"
    description    = "rules for incoming traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
  ingress {
    protocol       = "TCP"
    description    = "app port"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }
}

resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"
  resources {
    cores  = 2
    memory = 6
  }
  boot_disk {
    initialize_params {
      image_id = "fd8tgblovu5dklvrp29h"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
  metadata = {
    user-data = file("${path.module}/meta.yaml")
  }
  connection {
    type        = "ssh"
    user        = "vadim"
    private_key = file("~/.ssh/id_rsa")
    host        = self.network_interface.0.nat_ip_address
  }
  provisioner "remote-exec" {
    inline = [
      "ssudo apt-get install ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=\\\"$(dpkg --print-architecture)\\\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \\\"$(. /etc/os-release && echo \\\"$VERSION_CODENAME\\\")\\\" stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y",
      "sudo usermod -aG docker $USER",
      "git clone https://github.com/ShunkanTen/spring-petclinic.git",
      "cd ./spring-petclinic/",
      "sudo docker build . -t petclinic",
      "sudo docker network create net",
      "sudo docker compose up -d"
    ]
  }
}
