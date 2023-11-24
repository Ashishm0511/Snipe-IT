provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ashish-RG" {
  name     = "ashish-RG"
  location = "northeurope"
}


resource "azurerm_virtual_network" "ashish-RG" {
  name                = "vnet"
  resource_group_name = azurerm_resource_group.ashish-RG.name
  location            = azurerm_resource_group.ashish-RG.location
  address_space       = ["10.100.0.0/16"]

}


resource "azurerm_subnet" "ashish-RG" {
  name                 = "subnet01"
  resource_group_name  = azurerm_resource_group.ashish-RG.name
  virtual_network_name = azurerm_virtual_network.ashish-RG.name
  address_prefixes     = ["10.100.16.0/20"]
}



resource "azurerm_public_ip" "ashish-RG" {
  name                = "vm_public_ip"
  location            = azurerm_resource_group.ashish-RG.location
  resource_group_name = azurerm_resource_group.ashish-RG.name
  allocation_method   = "Static"

}

data "azurerm_public_ip" "public_ip" {
  name                = azurerm_public_ip.ashish-RG.name
  resource_group_name = azurerm_resource_group.ashish-RG.name
}



resource "azurerm_network_security_group" "ashish-RG" {
  name                = "sec_gro"
  location            = azurerm_resource_group.ashish-RG.location
  resource_group_name = azurerm_resource_group.ashish-RG.name


  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # security_rule {
  #   name                    = "allow-ports-10000-10050"
  #   protocol                = "Tcp"
  #   destination_port_ranges = ["10000-10050"]
  #   access                  = "Allow"
  #   priority                = 200
  #   direction               = "Inbound"
  # }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "ashish-RG" {
  name                = "nic"
  location            = azurerm_resource_group.ashish-RG.location
  resource_group_name = azurerm_resource_group.ashish-RG.name


  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.ashish-RG.id
    public_ip_address_id          = azurerm_public_ip.ashish-RG.id
  }
}

resource "azurerm_network_interface_security_group_association" "ashish-RG" {
  network_interface_id      = azurerm_network_interface.ashish-RG.id
  network_security_group_id = azurerm_network_security_group.ashish-RG.id
}


resource "azurerm_linux_virtual_machine" "ashish-RG" {

  name                = "ashish-Terraform-VM"
  resource_group_name = azurerm_resource_group.ashish-RG.name
  location            = azurerm_resource_group.ashish-RG.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "Password@12#"
  disable_password_authentication = false
  depends_on          = [azurerm_public_ip.ashish-RG]
  network_interface_ids = [
    azurerm_network_interface.ashish-RG.id,
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


  locals {
  data_inputs = <<-EOT
   #!/bin/bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw reload

   git clone https://github.com/snipe/snipe-it

   cd snipe-it

   ./install.sh <<EOF
  ${data.azurerm_public_ip.public_ip.ip_address}
   y
   n
   EOF
EOT

}
