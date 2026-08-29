region        = "us-east-1"
instance_type = "m7i.large"
disk_size     = 50
os            = "windows"

ssh_allowed_cidrs = []
rdp_allowed_cidrs = []
app_allowed_cidrs = ["0.0.0.0/0"]

# Set rdp_allowed_cidrs explicitly before exposing RDP.
# Supply TF_VAR_ssh_public_key through the environment.
