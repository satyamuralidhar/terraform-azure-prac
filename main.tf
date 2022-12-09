resource "azurerm_resource_group" "myrsg" {
  name = var.resourcegroup ? 1 :0
  location = var.location
  tags = local.tags
}

resource "azurerm_virtual_network" "myvnet" {
  name = format("%s-%s-%s",var.resourcegroup,var.location,"vnet")
  resource_group_name = azurerm_resource_group.myrsg.name
  location = azurerm_resource_group.myrsg.location
  address_space = [ "192.168.0.0/16" ]
  tags = local.tags
}

resource "azurerm_subnet" "mysubnet" {
    count = length(var.subnet_cidr)
    name = element(format("%s-%s-%s","subnet",azurerm_resource_group.myrsg.location,count.index+1))
    address_prefix = element(var.subnet_cidr,count.index)
    tags = local.tags
}

resource "azurerm_network_security_group" "nsg" {
  count = length(var.subnet_cidr)
  name = element("%s-%s-%s",azurerm_resource_group.myrsg.name,"nsg",count.index)
  location = azurerm_resource_group.myrsg.location

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
        name                       = security_rule.value["name"]
        priority                   = security_rule.value["priority"]
        direction                  = security_rule.value["direction"]
        access                     = security_rule.value["access"]
        protocol                   = security_rule.value["protocol"]
        source_port_range          = security_rule.value["source_port_range"]
        destination_port_range     = security_rule.value["destination_port_range"]
        source_address_prefix      = security_rule.value["source_address_prefix"]
        destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }

  tags = local.tags
}

resource "azurerm_network_interface_security_group_association" "nsgassociation" {
  network_security_group_id = azurerm_network_security_group.nsg[*].id  
  subnet_id = azurerm_subnet.mysubnet[*].id
}

resource "azurerm_route_table" "myrt" {
  name = var.routetable_name
  resource_group_name = azurerm_resource_group.myrsg.name
  location = azurerm_resource_group.myrsg.location

  route = {
    address_prefix = "0.0.0.0/0"
    name = "route1"
    next_hop_type = "Internet"
  }

}

resource "azurerm_subnet_route_table_association" "rtassociation" {
  subnet_id = azurerm_subnet.mysubnet[0].id
  route_table_id = azurerm_route_table.myrt.id
}

resource "azurerm_public_ip" "pip" {
  name = format("%s-$s",azurerm_virtual_network.myrsg.name,"pip")
  resource_group_name = azurerm_network_security_group.nsg.name
  location = azurerm_resource_group.myrsg.location
  allocation_method = "Dynamic"
  tags = local.tags
  
  depends_on = [
    azurerm_virtual_network.myvnet
  ]
}

resource "azurerm_network_interface" "mynic" {
  name = format("%s-%s",azurerm_resource_group.myrsg.name,var.nic_card)
  resource_group_name = azurerm_network_security_group.nsg.name
  location = azurerm_resource_group.myrsg.location
  
  ip_configuration {
    name = "mynicip"
    subnet_id = azurerm_subnet.mysubnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip.id
    
  }
}

/* ssh key creation */

resource "tls_private_key" "myprivate" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "mykey" {
  filename = "private.pem"
  content = tls_private_key.myprivate.private_key_pem
  file_permission = "0400"
}

/*linux vm creation with keys */

resource "azurerm_linux_virtual_machine" "myvm" {
  name = format("%s-%s",azurerm_resource_group.myrsg.name,mylinuxvm)
  location = azurerm_resource_group.myrsg.location
  resource_group_name = azurerm_resource_group.myrsg.name
  size = "Standard_D4s_v4"
  admin_username = "satya"
  network_interface_ids = [ azurerm_network_interface.mynic.id ]

  admin_ssh_key {
    username = "satya"
    public_key = tls_private_key.myprivate.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "14.04-LTS"
    version = "latest"
  }
  depends_on = [
    tls_private_key.myprivate,
    azurerm_virtual_network
  ]
}