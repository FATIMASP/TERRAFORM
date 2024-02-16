# main.tf
# Quickstart: Use Terraform to create a Windows VM
# LINK: https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-terraform

# 1) Create resource group
## Description: Creates an Azure Resource Group. Resource groups are containers that hold related resources for an Azure solution.
## Benefits: Helps in organizing and managing resources as a single management unit. Simplifies resource management, access control, and billing.
## Associations: Other resources like virtual network, subnet, public IP, NSG, NIC, VM, and storage account are associated with this resource group.
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${random_pet.prefix.id}-rg"  # Name of the resource group
}

# 2) Create virtual network
## Description: Creates a Virtual Network (VNet) in Azure. VNets help in logically isolating resources in Azure.
## Benefits: Enables communication between resources securely, helps in defining network boundaries, and facilitates network traffic control.
## Associations: Associated with the resource group. Subnet and public IP resources are associated with this virtual network.
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${random_pet.prefix.id}-vnet"  # Name of the virtual network
  address_space       = ["10.0.0.0/16"]  # IP address range for the virtual network
  location            = azurerm_resource_group.rg.location  # Location of the virtual network
  resource_group_name = azurerm_resource_group.rg.name  # Name of the resource group
}

# 3) Create subnet
## Description: Creates a subnet within a virtual network. Subnets help in dividing a VNet into smaller, manageable segments.
## Benefits: Provides segmentation for organizing and securing network traffic within a virtual network.
## Associations: Associated with the virtual network and the resource group.
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${random_pet.prefix.id}-subnet"  # Name of the subnet
  resource_group_name  = azurerm_resource_group.rg.name  # Name of the resource group
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name  # Name of the virtual network
  address_prefixes     = ["10.0.1.0/24"]  # IP address range for the subnet
}

# 4) Create public IPs
## Description: Creates a public IP address. Public IPs allow resources like virtual machines to communicate with the internet.
## Benefits: Enables internet connectivity for resources like virtual machines, enabling remote access and communication.
## Associations: Associated with the resource group. Assigned to the network interface for external communication.
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${random_pet.prefix.id}-public-ip"  # Name of the public IP
  location            = azurerm_resource_group.rg.location  # Location of the public IP
  resource_group_name = azurerm_resource_group.rg.name  # Name of the resource group
  allocation_method   = "Dynamic"  # IP allocation method
}

# 5) Create Network Security Group and rules
## Description: Creates a Network Security Group (NSG). NSGs act as virtual firewalls, filtering network traffic to and from Azure resources.
## Benefits: Enhances security by defining inbound and outbound traffic rules, controlling access to resources.
## Associations: Associated with the resource group. Connected to the network interface for controlling traffic flow.
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${random_pet.prefix.id}-nsg"  # Name of the network security group
  location            = azurerm_resource_group.rg.location  # Location of the network security group
  resource_group_name = azurerm_resource_group.rg.name  # Name of the resource group

  security_rule {
    name                       = "RDP"  # Name of the security rule
    priority                   = 1000  # Priority of the security rule
    direction                  = "Inbound"  # Direction of the security rule
    access                     = "Allow"  # Access permission of the security rule
    protocol                   = "*"  # Protocol of the security rule
    source_port_range          = "*"  # Source port range of the security rule
    destination_port_range     = "3389"  # Destination port range of the security rule
    source_address_prefix      = "*"  # Source address prefix of the security rule
    destination_address_prefix = "*"  # Destination address prefix of the security rule
  }

  security_rule {
    name                       = "web"  # Name of the security rule
    priority                   = 1001  # Priority of the security rule
    direction                  = "Inbound"  # Direction of the security rule
    access                     = "Allow"  # Access permission of the security rule
    protocol                   = "Tcp"  # Protocol of the security rule
    source_port_range          = "*"  # Source port range of the security rule
    destination_port_range     = "80"  # Destination port range of the security rule
    source_address_prefix      = "*"  # Source address prefix of the security rule
    destination_address_prefix = "*"  # Destination address prefix of the security rule
  }
}

# 6) Create network interface
## Description: Creates a network interface. Network interfaces attach to virtual machines and provide connectivity in a virtual network.
## Benefits: Facilitates communication between a virtual machine and other resources like VNets, public IPs, and NSGs.
## Associations: Associated with the resource group, virtual network, subnet, public IP, and NSG.
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${random_pet.prefix.id}-nic"  # Name of the network interface
  location            = azurerm_resource_group.rg.location  # Location of the network interface
  resource_group_name = azurerm_resource_group.rg.name  # Name of the resource group

  ip_configuration {
    name                          = "my_nic_configuration"  # Name of the IP configuration
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id  # ID of the subnet
    private_ip_address_allocation = "Dynamic"  # IP address allocation method
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id  # ID of the public IP
  }
}

# 7) Connect the security group to the network interface
## Description: Associates a network interface with a network security group. This association allows the NSG to filter traffic to and from the network interface.
## Benefits: Enforces security policies on traffic flowing to and from the associated network interface.
## Associations: Connects the network interface with the NSG for traffic filtering.
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id   = azurerm_network_interface.my_terraform_nic.id  # ID of the network interface
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id  # ID of the network security group
}

# 8) Create storage account for boot diagnostics
## Description: Creates a storage account in Azure. Storage accounts provide a unique namespace to store and access data objects in Azure.
## Benefits: Offers scalable, durable, and highly available storage solutions for various Azure services and applications.
## Associations: Associated with the resource group. Used for storing boot diagnostics data for the virtual machine.
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"  # Name of the storage account
  location                 = azurerm_resource_group.rg.location  # Location of the storage account
  resource_group_name      = azurerm_resource_group.rg.name  # Name of the resource group
  account_tier             = "Standard"  # Storage account tier
  account_replication_type = "LRS"  # Storage account replication type
}

# 9) Create virtual machine
## Description: Creates a Windows virtual machine in Azure. Virtual machines are scalable computing resources that run applications and workloads.
## Benefits: Provides flexibility, scalability, and control over computing resources. Ideal for hosting applications, websites, and services.
## Associations: Associated with the resource group, virtual network, subnet, network interface, public IP, NSG, and storage account.
resource "azurerm_windows_virtual_machine" "main" {
  name                          = "${var.prefix}-vm"  # Name of the virtual machine
  admin_username                = "azureuser"  # Admin username for the virtual machine
  admin_password                = random_password.password.result  # Admin password for the virtual machine
  location                      = azurerm_resource_group.rg.location  # Location of the virtual machine
  resource_group_name           = azurerm_resource_group.rg.name  # Name of the resource group
  network_interface_ids         = [azurerm_network_interface.my_terraform_nic.id]  # IDs of the network interfaces
  size                          = "Standard_DS1_v2"  # Size of the virtual machine

  os_disk {
    name              = "myOsDisk"  # Name of the OS disk
    caching           = "ReadWrite"  # Caching type for the OS disk
    storage_account_type = "Premium_LRS"  # Storage account type for the OS disk
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"  # Publisher of the source image
    offer     = "WindowsServer"  # Offer of the source image
    sku       = "2022-datacenter-azure-edition"  # SKU of the source image
    version   = "latest"  # Version of the source image
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint  # URI of the storage account for boot diagnostics
  }
}

# 10) Install IIS web server to the virtual machine
## Description: Adds an extension to the virtual machine. Extensions provide post-deployment configuration, automation, and management tasks.
## Benefits: Enables customization and automation of virtual machine configurations without manual intervention.
## Associations: Associated with the virtual machine. Installs IIS web server on the VM for hosting web applications.
resource "azurerm_virtual_machine_extension" "web_server_install" {
  name                       = "${random_pet.prefix.id}-wsi"  # Name of the virtual machine extension
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id  # ID of the virtual machine
  publisher                  = "Microsoft.Compute"  # Publisher of the virtual machine extension
  type                       = "CustomScriptExtension"  # Type of the virtual machine extension
  type_handler_version       = "1.8"  # Version of the virtual machine extension
  auto_upgrade_minor_version = true  # Auto upgrade minor version of the virtual machine extension

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
  }
  SETTINGS
}

# 11) Generate random id for a unique storage account name
## Description: Generates a random ID. Used here to create a unique name for the storage account.
## Benefits: Ensures uniqueness in naming resources, reducing the chance of naming conflicts.
## Associations: Associated with the resource group for generating unique storage account names.
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name  # Name of the resource group
  }

  byte_length = 8  # Length of the random ID in bytes
}

# 12) Generate random password
## Description: Generates a random password. Used to set the admin password for the virtual machine.
## Benefits: Enhances security by creating strong, random passwords for administrative access.
## Associations: Used to set the admin password for the virtual machine.
resource "random_password" "password" {
  length       = 20  # Length of the random password
  min_lower    = 1  # Minimum number of lowercase letters in the random password
  min_upper    = 1  # Minimum number of uppercase letters in the random password
  min_numeric  = 1  # Minimum number of numeric characters in the random password
  min_special  = 1  # Minimum number of special characters in the random password
  special      = true  # Include special characters in the random password
}

# 13) Generate random prefix
## Description: Generates a random pet name. Used for creating a unique prefix for various resources.
## Benefits: Provides a random, unique identifier for resource naming conventions, improving resource management.
## Associations: Used as a prefix for naming the resource group, virtual network, subnet, public IP, NSG, network interface, virtual machine, virtual machine extension, and storage account.
resource "random_pet" "prefix" {
  prefix = var.prefix  # Prefix for the random pet name
  length = 1  # Length of the random pet name
}
