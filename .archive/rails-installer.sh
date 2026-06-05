# Install dependencies with apt
sudo apt update
sudo apt install build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev curl

# Install Mise version manager
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >>~/.bashrc
source ~/.bashrc

# Install Ruby globally with Mise
mise use -g ruby@3

# Install rails
gem install rails
