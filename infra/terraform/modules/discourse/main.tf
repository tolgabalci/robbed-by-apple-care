# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-discourse"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Subnet for VM
resource "azurerm_subnet" "vm" {
  name                 = "subnet-discourse-vm"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for PostgreSQL (delegated)
resource "azurerm_subnet" "postgresql" {
  name                 = "subnet-discourse-postgresql"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Network Security Group for VM
resource "azurerm_network_security_group" "vm" {
  name                = "nsg-discourse-vm"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SSH access (restrict to specific IPs in production)
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_address_prefix
    destination_address_prefix = "*"
  }

  # HTTP from Front Door only
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  # HTTPS from Front Door only
  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Security Group for PostgreSQL
resource "azurerm_network_security_group" "postgresql" {
  name                = "nsg-discourse-postgresql"
  location            = var.location
  resource_group_name = var.resource_group_name

  # PostgreSQL access from VM subnet only
  security_rule {
    name                       = "PostgreSQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Public IP for VM
resource "azurerm_public_ip" "vm" {
  name                = "pip-discourse-vm"
  resource_group_name = var.resource_group_name
  location           = var.location
  allocation_method   = "Static"
  sku                = "Standard"
  zones              = ["1"]

  tags = var.tags
}

# Network Interface for VM
resource "azurerm_network_interface" "vm" {
  name                = "nic-discourse-vm"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = var.tags
}

# Associate Network Security Group to VM Subnet
resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# Associate Network Security Group to PostgreSQL Subnet
resource "azurerm_subnet_network_security_group_association" "postgresql" {
  subnet_id                 = azurerm_subnet.postgresql.id
  network_security_group_id = azurerm_network_security_group.postgresql.id
}

# User Assigned Managed Identity for VM
resource "azurerm_user_assigned_identity" "vm" {
  name                = "id-discourse-vm"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-discourse"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2s_v5"
  admin_username      = var.admin_username
  zone                = "1"

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }

  os_disk {
    name                 = "osdisk-discourse"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Custom data for initial setup
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
    admin_username = var.admin_username
  }))

  tags = var.tags
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "postgresql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = var.tags
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                         = "psql-discourse-${random_string.db_suffix.result}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "14"
  delegated_subnet_id          = azurerm_subnet.postgresql.id
  private_dns_zone_id          = azurerm_private_dns_zone.postgresql.id
  administrator_login          = "discourse_admin"
  administrator_password       = var.postgresql_admin_password
  zone                         = "1"
  storage_mb                   = 32768
  sku_name                     = "B_Standard_B1ms"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  high_availability {
    mode = "ZoneRedundant"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]

  tags = var.tags
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "discourse" {
  name      = "discourse_production"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL Firewall Rule (allow VM subnet)
resource "azurerm_postgresql_flexible_server_firewall_rule" "vm_subnet" {
  name             = "AllowVMSubnet"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "10.0.1.0"
  end_ip_address   = "10.0.1.255"
}

resource "random_string" "db_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Storage Account for Discourse uploads (S3-compatible)
resource "azurerm_storage_account" "discourse" {
  name                     = "stdiscourse${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable S3-compatible access
  is_hns_enabled = false

  # Security settings
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Network access
  network_rules {
    default_action             = "Allow"
    virtual_network_subnet_ids = [azurerm_subnet.vm.id]
  }

  tags = var.tags
}

# Container for Discourse uploads
resource "azurerm_storage_container" "uploads" {
  name                  = "discourse-uploads"
  storage_account_name  = azurerm_storage_account.discourse.name
  container_access_type = "private"
}

# Container for Discourse backups
resource "azurerm_storage_container" "backups" {
  name                  = "discourse-backups"
  storage_account_name  = azurerm_storage_account.discourse.name
  container_access_type = "private"
}

# Storage Account Access Key (for S3-compatible access)
data "azurerm_storage_account" "discourse" {
  name                = azurerm_storage_account.discourse.name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_storage_account.discourse]
}

resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}