# Elastic ip 
resource "aws_eip" "myeip" {
  tags = {
    Name = "myeip"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip}"
  }
}