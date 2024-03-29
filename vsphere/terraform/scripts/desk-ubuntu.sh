
##################################
# Update apt
sudo apt update
sudo apt install command-not-found
sudo apt update

# sudo /usr/lib/command-not-found -- dig

# What is the proper way to install it when missing?
cat >> $HOME/.bashrc <<'EOF'
command_not_found_handle() {
  if  [ -x /usr/lib/command-not-found ]; then
     /usr/lib/command-not-found -- "$1" 
     return $?
  else
     return 127
  fi        
}
EOF

##################################
# Utils
sudo apt install -y \
  iputils-ping \
  bind9-dnsutils \
  inetutils-traceroute \
  iputils-arping \
  arp-scan

##################################
# So emojis render
sudo apt install -y fonts-noto-color-emoji

# Copy a ~/.profile
# Copy a ~/.bashrc
# Copy a $profile for pwsh


##################################
# VSCode
wget -o $HOME/code.tar.gz https://code.visualstudio.com/sha/download?build=stable&os=linux-x64
mkdir -p $HOME/apps/vscode
tar -xzvf $HOME/code.tar.gz -C $HOME/app/vscode
ln -s $HOME/.local/bin/code $HOME/app/vscode/code


##################################
# Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
# sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y xorriso packer


##################################
# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update

sudo apt install terraform


##################################
## Powershell

# Install system components
sudo apt update  && sudo apt install -y curl gnupg apt-transport-https

# Import the public repository GPG keys
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Register the Microsoft Product feed
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-bullseye-prod bullseye main" > /etc/apt/sources.list.d/microsoft.list'

# Install PowerShell
sudo apt update
sudo apt install -y powershell
