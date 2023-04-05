# Nat Gateway
resource "aws_nat_gateway" "mygw" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.public1.id
}
