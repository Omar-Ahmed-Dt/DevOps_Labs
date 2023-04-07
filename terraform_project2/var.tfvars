# main_subnet = "10.0.0.0/16"
main_subnet = [{subnet = "10.0.0.0/16", name = "production"}]
# subnet_prefix = ["10.0.1.0/24","10.0.2.0/24"]
subnet_prefix = [{cidr_block = "10.0.1.0/24", name = "prod"},{cidr_block = "10.0.2.0/24", name = "dev"}]