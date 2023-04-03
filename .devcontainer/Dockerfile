FROM mcr.microsoft.com/devcontainers/python:0-3.9

# install starship
RUN wget https://starship.rs/install.sh && \
    chmod +x install.sh && \
    ./install.sh --yes && \
    rm install.sh

#install terraform
RUN version='1.4.1'; \
    curl "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip" -o "terraform.zip" && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin && chmod +x /usr/local/bin/terraform

#install latest version of aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install
