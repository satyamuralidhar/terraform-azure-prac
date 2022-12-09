subnet_cidr = ["192.168.1.0/24","192.168.2.0/24"]
resourcegroup = false
location = "us-east-1"
nic_card = "vm-nic-card"
routetable_name = "my_tb"

nsg_rules = [
    {
        name                       = "Allow-Web-In"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    },
    {
        name                       = "Allow-SSH-In"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    },
    {
        name                       = "Allow-Jenkins-In"
        priority                   = 102
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

]