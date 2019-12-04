# Developing inside a Container

### The Visual Studio Code Remote - Containers extension lets you use a Docker container as a full-featured development environment.

## Python

- ### Anaconda3 2019.10

```
docker build -f anaconda3.Dockerfile --tag mrsono0/devremotecontainers:anaconda3 .

docker run --rm --name anaconda3 -itd mrsono0/devremotecontainers:anaconda3

docker run --rm --name anaconda3 -itd -p 8888:8888 mrsono0/devremotecontainers:anaconda3 /bin/bash -c "mkdir /opt/notebooks && /opt/conda/bin/jupyter notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name anaconda3 -itd -p 8888:8888 mrsono0/devremotecontainers:anaconda3 /bin/bash -c "mkdir /opt/notebooks && /opt/conda/bin/jupyter lab --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name anaconda3 -itd -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 mrsono0/devremotecontainers:anaconda3 /bin/bash -c "mkdir -p /home/vscode/notebooks && /opt/conda/bin/jupyter lab --notebook-dir=/home/vscode/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name anaconda3 -itd -u vscode -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 -e JUPYTER_RUN=yes mrsono0/devremotecontainers:anaconda3

docker push mrsono0/devremotecontainers:anaconda3
```

- ### Miniconda3 4.7.12

```
docker build -f miniconda3.Dockerfile --tag mrsono0/devremotecontainers:miniconda3 .

docker run --rm --name miniconda3 -itd mrsono0/devremotecontainers:miniconda3

docker run --rm --name miniconda3 -itd -p 8888:8888 mrsono0/devremotecontainers:miniconda3 /bin/bash -c "mkdir /opt/notebooks && /opt/conda/bin/jupyter notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name miniconda3 -itd -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 mrsono0/devremotecontainers:miniconda3 /bin/bash -c "mkdir /opt/notebooks && /opt/conda/bin/jupyter lab --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name miniconda3 -itd -u vscode -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 -e JUPYTER_RUN=yes mrsono0/devremotecontainers:miniconda3

docker push mrsono0/devremotecontainers:miniconda3
```

- ### Python 3.7.5

```
docker build -f python3.7.5.Dockerfile --tag mrsono0/devremotecontainers:python3.7.5 .

docker run --rm --name python3.7.5 -itd mrsono0/devremotecontainers:python3.7.5

docker run --rm --name python3.7.5 -itd -p 8888:8888 mrsono0/devremotecontainers:python3.7.5 /bin/bash -c "mkdir /opt/notebooks && jupyter notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name python3.7.5 -itd -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 mrsono0/devremotecontainers:python3.7.5 /bin/bash -c "mkdir /opt/notebooks && jupyter lab --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name python3.7.5 -itd -u vscode -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 -e JUPYTER_RUN=yes mrsono0/devremotecontainers:python3.7.5

docker push mrsono0/devremotecontainers:python3.7.5

python3 -m pip install --upgrade pip
```

- ### Python 3.8

```
docker build -f python3.8.Dockerfile --tag mrsono0/devremotecontainers:python3.8 .

docker run --rm --name python3.8 -itd mrsono0/devremotecontainers:python3.8

docker run --rm --name python3.8 -itd -p 8888:8888 mrsono0/devremotecontainers:python3.8 /bin/bash -c "mkdir /opt/notebooks && jupyter notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name python3.8 -itd -p 8888:8888 mrsono0/devremotecontainers:python3.8 /bin/bash -c "mkdir /opt/notebooks && jupyter lab --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name python3.8 -itd -u vscode -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 -e JUPYTER_RUN=yes mrsono0/devremotecontainers:python3.8

docker push mrsono0/devremotecontainers:python3.8
```

## R-base

- ### R 3.6.1

```
docker build -f r3.6.1.Dockerfile --tag mrsono0/devremotecontainers:r3.6.1 .

docker run --rm --name r3.6.1 -itd mrsono0/devremotecontainers:r3.6.1

docker run --rm --name r3.6.1 -itd -p 8888:8888 mrsono0/devremotecontainers:r3.6.1 /bin/bash -c "mkdir /opt/notebooks && jupyter notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name r3.6.1 -it -p 8888:8888 mrsono0/devremotecontainers:r3.6.1 /bin/bash -c "mkdir /opt/notebooks && jupyter lab --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name r3.6.1 -itd -u vscode -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 -e JUPYTER_RUN=yes mrsono0/devremotecontainers:r3.6.1

docker push mrsono0/devremotecontainers:r3.6.1
```

- ### R-devel 3.6.1

```
docker build -f r-devel3.6.1.Dockerfile --tag mrsono0/devremotecontainers:r-devel3.6.1 .

docker run --rm --name r-devel3.6.1 -itd mrsono0/devremotecontainers:r-devel3.6.1

docker run --rm --name r-devel3.6.1 -itd -p 8888:8888 mrsono0/devremotecontainers:r-devel3.6.1 /bin/bash -c "mkdir /opt/notebooks && jupyter notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name r-devel3.6.1 -itd -p 8888:8888 mrsono0/devremotecontainers:r-devel3.6.1 /bin/bash -c "mkdir /opt/notebooks && jupyter lab --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker push mrsono0/devremotecontainers:r-devel3.6.1
```

## Java

- ### OpenJDK8

```
docker build -f openjdk8.Dockerfile --tag mrsono0/devremotecontainers:openjdk8 .

docker run --rm --name openjdk8 -itd mrsono0/devremotecontainers:openjdk8

docker run --rm --name openjdk8 -itd -p 8888:8888 mrsono0/devremotecontainers:openjdk8 /bin/bash -c "mkdir /notebooks && jupyter notebook --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name openjdk8 -it -p 8888:8888 mrsono0/devremotecontainers:openjdk8 /bin/bash -c "mkdir /notebooks && jupyter lab --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name openjdk8 -itd -u vscode -p 8888:8888 -p 8088:8088 -p 6006-6015:6006-6015 -e JUPYTER_RUN=yes mrsono0/devremotecontainers:openjdk8

docker push mrsono0/devremotecontainers:openjdk8
```

- ### OpenJDK11

```
docker build -f openjdk11.Dockerfile --tag mrsono0/devremotecontainers:openjdk11 .

docker run --rm --name openjdk11 -it mrsono0/devremotecontainers:openjdk11

docker run --rm --name openjdk11 -itd -p 8888:8888 mrsono0/devremotecontainers:openjdk11 /bin/bash -c "mkdir /notebooks && jupyter notebook --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name openjdk11 -it -p 8888:8888 mrsono0/devremotecontainers:openjdk11 /bin/bash -c "mkdir -p /home/vscode/notebooks && jupyter lab --notebook-dir=/home/vscode/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker push mrsono0/devremotecontainers:openjdk11

docker build -f openjdk13.Dockerfile --tag mrsono0/devremotecontainers:openjdk13 .
docker push mrsono0/devremotecontainers:openjdk13
```

- ### Oracle JDK 8

```
docker build -f oraclejdk8.Dockerfile --tag mrsono0/devremotecontainers:oraclejdk8 .

docker run --rm --name oraclejdk8 -it mrsono0/devremotecontainers:oraclejdk8

docker run --rm --name oraclejdk8 -itd -p 8888:8888 mrsono0/devremotecontainers:oraclejdk8 /bin/bash -c "mkdir /opt/notebooks && /opt/conda/bin/jupyter notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name oraclejdk8 -itd -p 8888:8888 mrsono0/devremotecontainers:oraclejdk8 /bin/bash -c "mkdir /opt/notebooks && /opt/conda/bin/jupyter lab --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker push mrsono0/devremotecontainers:oraclejdk8
```

- ### Oracle JDK 11

```
docker build -f oraclejdk11.Dockerfile --tag mrsono0/devremotecontainers:oraclejdk11 .

docker run --rm --name oraclejdk11 -it mrsono0/devremotecontainers:oraclejdk11

docker run --rm --name oraclejdk11 -itd -p 8888:8888 mrsono0/devremotecontainers:oraclejdk11 /bin/bash -c "mkdir /notebooks && jupyter notebook --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name oraclejdk11 -itd -p 8888:8888 mrsono0/devremotecontainers:oraclejdk11 /bin/bash -c "mkdir /notebooks && jupyter lab --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker push mrsono0/devremotecontainers:oraclejdk11
```

## Node.js

- ### node.js 12.13.0

```
docker build -f nodejs12.13.0.Dockerfile --tag mrsono0/devremotecontainers:nodejs12.13.0 .

docker run --rm --name nodejs12.13.0 -it mrsono0/devremotecontainers:nodejs12.13.0

docker run --rm --name nodejs12.13.0 -itd -p 8888:8888 mrsono0/devremotecontainers:nodejs12.13.0 /bin/bash -c "mkdir /notebooks && jupyter notebook --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name nodejs12.13.0 -it -p 8888:8888 mrsono0/devremotecontainers:nodejs12.13.0 /bin/bash -c "mkdir /notebooks && jupyter lab --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker push mrsono0/devremotecontainers:nodejs12.13.0
```

## AI

- ### ai and Docker-for-AI-Researcher

```
docker build -f ai.Dockerfile --tag mrsono0/devremotecontainers:ai .

docker run --rm --name ai -it mrsono0/devremotecontainers:ai

docker run --rm --name ai -itd -p 8888:8888 mrsono0/devremotecontainers:ai /bin/bash -c "mkdir /notebooks && jupyter notebook --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm --name ai -it -p 8888:8888 mrsono0/devremotecontainers:ai /bin/bash -c "mkdir /notebooks && jupyter lab --notebook-dir=/notebooks --ip='*' --port=8888 --no-browser --allow-root"

docker run --rm -it --name vscode -p 8088:8080 -p 6006-6015:6006-6015 -v ~/docker:/data -e PASSWORD="0000" --ipc=host mrsono0/devremotecontainers:ai code-server

docker push mrsono0/devremotecontainers:ai
```

- ### vscode server

```
docker build -f vscode-server.Dockerfile --tag mrsono0/devremotecontainers:vscode-server .

docker run --rm --name vscode-server -it mrsono0/devremotecontainers:vscode-server

docker run --rm -it --name vscode -u vscode -p 8088:8088 -p 6006-6015:6006-6015 -v ~/docker:/home/vscode/docker -e PASSWORD="000000" mrsono0/devremotecontainers:vscode-server

docker run --rm -itd --name vscode -u vscode -p 8088:8088 -p 6006-6015:6006-6015 mrsono0/devremotecontainers:vscode-server
docker run --rm -itd --name vscode -p 8088:8088 -p 6006-6015:6006-6015 mrsono0/devremotecontainers:vscode-server

docker push mrsono0/devremotecontainers:vscode-server
```

## Developing inside a Container

```
git clone https://github.com/Microsoft/vscode-remote-try-node
git clone https://github.com/Microsoft/vscode-remote-try-python
git clone https://github.com/Microsoft/vscode-remote-try-go
git clone https://github.com/Microsoft/vscode-remote-try-java
git clone https://github.com/Microsoft/vscode-remote-try-dotnetcore
git clone https://github.com/Microsoft/vscode-remote-try-php
git clone https://github.com/Microsoft/vscode-remote-try-rust
git clone https://github.com/Microsoft/vscode-remote-try-cpp
```