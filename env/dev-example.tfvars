#####################
#Bootstrap Variables# 
#####################
state_container_name = "terraform-state"
state_key            = "wrg-terrafom-vm-data-science-windows.dev-example"

##################################################
#Regular Terraform Environment Specific Variables#
##################################################
env="dev"
prefix = "WrG"
machine_number = "001"
location       = "eastus2"
size           = "Standard_F8s_v2"
users_group    = "test_user_group"
timezone = "Eastern Standard Time"

tags = {
  project = "wrg-terraform-vm-data-science-windows"
}
