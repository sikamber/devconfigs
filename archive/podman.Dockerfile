
FROM ubuntu


# Add app for newer version of neovim (needed for lazyvim), including requirements 
# for adding ppa
RUN apt-get update
RUN apt-get install -y wget gnupg2 software-properties-common
RUN add-apt-repository ppa:neovim-ppa/unstable

# Install packages
RUN apt-get update
RUN apt-get install -y \
        curl \
        git \
        gh \
        vim \
        neovim \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        fd-find \
        unzip \
        locales \
        python3-dev \
        default-libmysqlclient-dev \
        build-essential \
        pkg-config && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# Install NodeJS 22 (needed for treesitter
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g tree-sitter-cli

# Set locale environment variables
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TZ Europe/Copenhagen

# Create a non-root user
RUN useradd -ms /bin/bash devuser

# Symlink fd (Debian/Ubuntu uses 'fdfind')
RUN ln -s $(which fdfind) /usr/local/bin/fd

COPY .config/nvim /root/.config/nvim
RUN mkdir /root/workspace
# RUN touch /home/devuser/workspace/init
# RUN chown -R devuser:devuser /home/devuser
# RUN chown -R devuser:devuser /home/devuser/workspace

# Install UV (needs to belong to user)
RUN curl -Ls https://astral.sh/uv/install.sh | bash

# Preinstall nvim plugins
RUN nvim --headless "+Lazy! sync" +qa

RUN echo "cd /root/workspace" >> /root/.bashrc
ENTRYPOINT ["/bin/bash", "-c"]

