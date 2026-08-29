region        = "us-east-1"
instance_type = "t3.small"
disk_size     = 20
os            = "linux"

ssh_allowed_cidrs = []
app_allowed_cidrs = ["0.0.0.0/0"]

# Supply secrets through environment variables, for example:
# TF_VAR_ssh_public_key
# TF_VAR_db_password
