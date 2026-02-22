# Neovim and nodejs
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install -y curl git gh ripgrep fd-find neovim
sudo curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install nodejs

# Python and UV
sudo apt install -y python3 python3-pip python3-venv
curl -LsSf https://astral.sh/uv/install.sh | sh
