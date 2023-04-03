#!/bin/bash

#install starship,add it to bash,set config
echo 'eval "$(starship init bash)"' >> ~/.bashrc
mkdir -p ~/.config
cp ./.devcontainer/starship.toml ~/.config/starship.toml
