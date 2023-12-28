terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.99.1"
}

provider "yandex" {
  zone                     = "ru-central1-a"
  folder_id                = "b1g3uc18j583qsjkeuba"
  cloud_id                 = "b1g5t19bqubd71dfm42j"
  service_account_key_file = ("${path.module}/key.json")
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
}

resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"

  resources {
    cores  = 2
    memory = 6
  }

  boot_disk {
    initialize_params {
      image_id = "fd8k54g2t50mekbk1ie1"
      size     = 10
    }
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.subnet-1.id
    nat            = true
    nat_ip_address = "84.201.134.185"
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
      "sudo apt-get install ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=\\\"$(dpkg --print-architecture)\\\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \\\"$(. /etc/os-release && echo \\\"$VERSION_CODENAME\\\")\\\" stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y",
      "sudo usermod -aG docker $USER",
      "git clone https://github.com/ShunkanTen/Petclinic_Terraform_YC.git",
      "cd ~/Petclinic_Terraform_YC/spring-petclinic/",
      "sudo docker build . -t petclinic",
      "sudo docker network create net",
      "sudo docker compose up -d",
      "sudo apt-get install docker-compose -y"
    ]
  }
}
