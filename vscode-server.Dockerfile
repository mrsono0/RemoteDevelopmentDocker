FROM debian:buster-slim

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV SERVICE_URL=https://marketplace.visualstudio.com/vscode
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 SHELL=/bin/bash
ENV LANGUAGE=${LANG} TZ=Asia/Seoul
ENV PATH=/usr/local/coder:/opt/conda/bin:$PATH

RUN apt-get update --fix-missing && \
    apt-get install -y wget curl bzip2 libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion \
	bash-completion \
	ca-certificates \
    software-properties-common \
    apt-transport-https \
    tzdata vim nano neovim git-lfs \
    openssl locales dumb-init \
    supervisor \
    && apt-get clean

 # timezone settings
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && echo $TZ > /etc/timezone

# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
# https://github.com/cdr/code-server/releases
ENV vscode_version=2.1692-vsc1.39.2
ENV vscode_filename=code-server2.1692-vsc1.39.2-linux-x86_64
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for non-root user
    && apt-get install -y sudo \
    nodejs \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && mkdir -p /usr/local/coder \
    && wget https://github.com/cdr/code-server/releases/download/${vscode_version}/${vscode_filename}.tar.gz \
    && tar -xvf ${vscode_filename}.tar.gz \
    && mv ${vscode_filename} coder \
    && mv coder /usr/local/ \
    && chmod +x /usr/local/coder/code-server \
    && ln -s /usr/local/coder/code-server /usr/local/bin/code-server \
    && rm -f ${vscode_filename}.tar.gz \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN unset vscode_version vscode_filename
COPY ETC/entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

# COPY ETC/donjayamanne.python-extension-pack-1.6.0.vsix /home/vscode
# COPY ETC/ms-python.python-2019.11.50794.vsix /home/vscode
# COPY ETC/ms-python.anaconda-extension-pack-1.0.1.vsix /home/vscode
COPY ETC/MS-CEINTL.vscode-language-pack-ko-1.40.2.vsix /home/vscode
COPY ETC/vscode-icons-team.vscode-icons-9.6.0.vsix /home/vscode
RUN code-server --install-extension /home/vscode/vscode-icons-team.vscode-icons-9.6.0.vsix
USER vscode
RUN code-server --install-extension /home/vscode/vscode-icons-team.vscode-icons-9.6.0.vsix
USER root
RUN rm -f /home/vscode/*.vsix

# RUN locale-gen --purge
# RUN locale-gen ko_KR.UTF-8
# RUN dpkg-reconfigure locales
# RUN echo 'LANG="ko_KR.UTF-8"' >> /etc/environment && \
#     # echo 'LANG="ko_KR.EUC-KR"' >> /etc/environment && \
#     echo 'LANGUAGE="ko_KR;ko;en_GB;en"' >> /etc/environment && \
#     echo 'LC_ALL="ko_KR.UTF-8"' >> /etc/environment
# RUN echo 'export LANG="ko_KR.UTF-8"' >> /etc/profile && \
#     # echo 'export LANG="ko_KR.EUC-KR"' >> /etc/profile && \
#     echo 'export LANGUAGE="ko_KR;ko;en_GB;en"' >> /etc/profile && \
#     echo 'export LC_ALL="ko_KR.UTF-8"' >> /etc/profile && \
#     echo "export QT_XKB_CONFIG_ROOT=/usr/share/X11/locale" >> /etc/profile
# RUN echo 'LANG="ko_KR.UTF-8"' >> /etc/default/locale && \
#     # echo 'LANG="ko_KR.EUC-KR"' >> /etc/default/locale && \
#     echo 'LANGUAGE="ko_KR;ko;en_GB;en"' >> /etc/default/locale && \
#     echo 'LC_ALL="ko_KR.UTF-8"' >> /etc/default/locale

# ENV PASSWORD "000000"
EXPOSE 6006-6015 8080 8888
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD [ "/bin/bash" ]