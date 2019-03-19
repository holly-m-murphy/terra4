terraform{
  backend "s3" {
   bucket="table2hmterraform"
   key="terra4/state"
   region="eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias = "us-east-2"
  region = "us-east-2"
}

variable "zones"{
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "zones-2"{
  default = ["us-east-2a", "us-east-2b"]
}

variable "env-name"{
  default = "pre-prod"
}

variable "multi-region"{
  default = true
}

resource "aws_instance" "taco-frontend" {
  count = 1
  availability_zone = "${var.zones[count.index]}"
  depends_on = ["aws_instance.taco-backend"]
  ami = "ami-08660f1c6fb6b01e7"
  instance_type = "t2.micro"
  key_name = "taco"
  tags = {
    Name = "${join("-",list(var.env-name, "taco-frontend"))}"
  }
  security_groups = ["default"]
  provisioner "remote-exec"{
    inline = ["sudo apt-get -y update",
              "sudo apt-get install -y nginx",
              "sudo service nginx start"]
    connection{
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("/home/ubuntu/tacos")}"
    }
  }
  lifecycle{
    create_before_destroy = true
  }
}

output "taco_frontend_ip"{
  value = "${aws_instance.taco-frontend.*.public_ip}"
}

resource "aws_instance" "taco-backend" {
  count = "${var.multi-region ? 1:2}"
  availability_zone = "${var.zones-2[count.index]}"
  ami = "ami-0e7589a8422e3270f"
  instance_type = "t2.micro"
  key_name = "taco"
  tags = {
    Name = "${join("-",list(var.env-name, "taco-backend"))}"
  }
  security_groups = ["default"]
  provider = "aws.us-east-2"
  lifecycle{
    create_before_destroy = true
  }
}

output "taco_backend_ip"{
  value = "${aws_instance.taco-backend.*.public_ip}"
}

