FROM mrsono0/devremotecontainers:vscode-server

RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

RUN bash -c "/opt/conda/bin/conda install jupyter -y --quiet"
RUN bash -c "/opt/conda/bin/conda install jupyterlab -y --quiet"
RUN bash -c "/opt/conda/bin/conda install pylint -y --quiet"
RUN if [ ! -d "/usr/local/anaconda3" ]; then ln -s /opt/conda /usr/local/anaconda3; fi
# RUN pip --disable-pip-version-check --no-cache-dir install pylint
# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY ETC/entrypoint.anaconda3.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY ETC/ms-python.python-2019.11.50794.vsix /home/vscode
COPY ETC/ms-python.anaconda-extension-pack-1.0.1.vsix /home/vscode
COPY ETC/CoenraadS.bracket-pair-colorizer-2-0.0.29.vsix /home/vscode
COPY ETC/jithurjacob.nbpreviewer-1.2.2.vsix /home/vscode
COPY ETC/donjayamanne.python-extension-pack-1.6.0.vsix /home/vscode
COPY ETC/formulahendry.code-runner-0.9.15.vsix /home/vscode
COPY ETC/tht13.python-0.2.3.vsix /home/vscode

RUN code-server --install-extension /home/vscode/ms-python.python-2019.11.50794.vsix
RUN code-server --install-extension /home/vscode/ms-python.anaconda-extension-pack-1.0.1.vsix 
RUN code-server --install-extension /home/vscode/CoenraadS.bracket-pair-colorizer-2-0.0.29.vsix
RUN code-server --install-extension /home/vscode/jithurjacob.nbpreviewer-1.2.2.vsix
RUN code-server --install-extension /home/vscode/donjayamanne.python-extension-pack-1.6.0.vsix
RUN code-server --install-extension /home/vscode/formulahendry.code-runner-0.9.15.vsix
RUN code-server --install-extension /home/vscode/tht13.python-0.2.3.vsix
USER vscode
RUN code-server --install-extension /home/vscode/ms-python.python-2019.11.50794.vsix
RUN code-server --install-extension /home/vscode/ms-python.anaconda-extension-pack-1.0.1.vsix 
RUN code-server --install-extension /home/vscode/CoenraadS.bracket-pair-colorizer-2-0.0.29.vsix
RUN code-server --install-extension /home/vscode/jithurjacob.nbpreviewer-1.2.2.vsix
RUN code-server --install-extension /home/vscode/donjayamanne.python-extension-pack-1.6.0.vsix
RUN code-server --install-extension /home/vscode/formulahendry.code-runner-0.9.15.vsix
RUN code-server --install-extension /home/vscode/tht13.python-0.2.3.vsix
USER root
RUN rm -f /home/vscode/*.vsix