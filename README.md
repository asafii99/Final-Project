The purpose of this DevOps project is to automate the provisioning, configuring, and deploying of an HTML web application using Terraform, Ansible, and Jenkins.

Instructions for how to deploy this DevOps Project:

1. Create an SSH key and an AWS account.
<<<<<<< HEAD
2. Copy and paste your account details into ~/.aws/credentials if you're using an AWS Educate account or create an API key within AWS to use with Terraform if you're using a normal AWS account.
3. Install both Ansible and Terraform onto your linux system. 
4. Create a terraform.tfvars file and define your variables which are contained in variables.tf. 
5. If needed, make any other modifications/changes depending on your environment. 
7. Run the "terraform init" command. 
=======
2. Copy and paste your account details into ~/.aws/credentials if your using an AWS Educate account or create an API key within AWS to use with Terraform if you're using a normal AWS account.
3. Install both Ansible and Terraform onto your linux system.
4. Create a terraform.tfvars file and define your variables which are contained in variables.tf.
5. If needed, make any other modifications/changes depending on your environment.
7. Run the "terraform init" command.
>>>>>>> 0bc8fe7cf0214bf151794fbd75881a6646ea73e7
6. Lastly, run the "terraform apply" command.
