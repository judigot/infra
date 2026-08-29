region        = "us-east-1"
instance_type = "c5ad.large"
disk_size     = 30
os            = "linux"

ssh_allowed_cidrs = []
app_allowed_cidrs = ["0.0.0.0/0"]
database_publicly_accessible = false
database_allowed_cidrs = []

# Supply secrets through environment variables, for example:
# TF_VAR_ssh_public_key
# TF_VAR_db_password
