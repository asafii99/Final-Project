The purpose of this DevOps project is to automate the provisioning, configuring, and deploying of an HTML web application using Terraform, Ansible, and Jenkins.

Instructions for how to deploy this DevOps Project:

1. Create an SSH key and an AWS account.
2. Copy and paste your account details into ~/.aws/credentials if you're using an AWS Educate account or create an API key within AWS to use with Terraform if you're using a normal AWS account.
3. Install both Ansible and Terraform onto your Linux system. 
4. Create a terraform.tfvars file and define your variables which are contained in variables.tf. 
5. If needed, make any other modifications/changes depending on your environment. 
6. Run the "terraform init" command. 
7. Lastly, run the "terraform apply" command.

Instructions for how Jenkins deploys code automatically via the dev branch and head commits:

1. On Jenkins, go to Manage Plugins and add the two plugins, "SSH plugin" and "Publish Over SSH".
2. Go to Configure System and under SSH remote hosts, add in your SSH sites that your project will connect to.
3. Under Publish Over SSH, add in your SSH Server/s.
4. Add a new item and select the "Freestyle project".
5. Under Source Code Management, add the Git repository and specify your branch.
6. Under Build Triggers, select the GitHub hook trigger for GITScm polling.
7. Under Build, add a build step and select Execute shell script on remote host using ssh, then select your SSH site and enter "sudo chmod 777 /var/www/html" as your command.
8. Under Post-build artifacts, add a post-build action and select Send build artifacts over SSH, then select your SSH server.
9. Save your job and go over to your GitHub repository and in settings add a webhook.
10. Make changes to the code and commit the changes to automatically notify Jenkins to automatically run a build. 
