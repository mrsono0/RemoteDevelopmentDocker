FROM mrsono0/devremotecontainers:python3.7.5 

## https://github.com/rocker-org/rocker-versioned/blob/master/r-ver/Dockerfile
## https://github.com/rocker-org/rocker/blob/master/r-devel/Dockerfile
## r spark - https://github.com/saagie/rstudio-docker/blob/master/Dockerfile

ARG R_VERSION
ARG BUILD_DATE
ENV R_VERSION=${R_VERSION:-3.6.1} \
	TERM=xterm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	ed \
	gpg \
	less \
	locales \
	vim-tiny \
	wget \
	ca-certificates \
	fonts-texgyre \
	tzdata vim nano git \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

## Use Debian unstable via pinning -- new style via APT::Default-Release
RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
	&& echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default

ENV R_BASE_VERSION 3.6.1

## Now install R and littler, and create a link for littler in /usr/local/bin
RUN apt-get update \
	&& apt-get install -t unstable -y --no-install-recommends \
	littler \
	r-cran-littler \
	r-base=${R_BASE_VERSION}-* \
	r-base-dev=${R_BASE_VERSION}-* \
	r-recommended=${R_BASE_VERSION}-* \
	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& apt-get clean \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*

RUN rm /etc/apt/apt.conf.d/default
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	# utilities for keeping Debian and OpenJDK CA certificates in sync
	ca-certificates p11-kit \
	; \
	rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/local/openjdk-8
ENV PATH $JAVA_HOME/bin:$PATH

# backwards compatibility shim
RUN { echo '#/bin/sh'; echo 'echo "$JAVA_HOME"'; } > /usr/local/bin/docker-java-home && chmod +x /usr/local/bin/docker-java-home && [ "$JAVA_HOME" = "$(docker-java-home)" ]

# https://adoptopenjdk.net/upstream.html
ENV JAVA_VERSION 8u232
ENV JAVA_BASE_URL https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries/releases/download/jdk8u232-b09/OpenJDK8U-jdk_
ENV JAVA_URL_VERSION 8u232b09
# https://github.com/docker-library/openjdk/issues/320#issuecomment-494050246

RUN set -eux; \
	\
	dpkgArch="$(dpkg --print-architecture)"; \
	case "$dpkgArch" in \
	amd64) upstreamArch='x64' ;; \
	arm64) upstreamArch='aarch64' ;; \
	*) echo >&2 "error: unsupported architecture: $dpkgArch" ;; \
	esac; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	dirmngr \
	gnupg \
	wget \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	wget -O openjdk.tgz.asc "${JAVA_BASE_URL}${upstreamArch}_linux_${JAVA_URL_VERSION}.tar.gz.sign"; \
	wget -O openjdk.tgz "${JAVA_BASE_URL}${upstreamArch}_linux_${JAVA_URL_VERSION}.tar.gz" --progress=dot:giga; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	# TODO find a good link for users to verify this key is right (https://mail.openjdk.java.net/pipermail/jdk-updates-dev/2019-April/000951.html is one of the only mentions of it I can find); perhaps a note added to https://adoptopenjdk.net/upstream.html would make sense?
	# no-self-sigs-only: https://salsa.debian.org/debian/gnupg2/commit/c93ca04a53569916308b369c8b218dad5ae8fe07
	gpg --batch --keyserver ha.pool.sks-keyservers.net --keyserver-options no-self-sigs-only --recv-keys CA5F11C6CE22644D42C6AC4492EF8D39DC13168F; \
	# also verify that key was signed by Andrew Haley (the OpenJDK 8 and 11 Updates OpenJDK project lead)
	# (https://github.com/docker-library/openjdk/pull/322#discussion_r286839190)
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys EAC843EBD3EFDB98CC772FADA5CD6035332FA671; \
	gpg --batch --list-sigs --keyid-format 0xLONG CA5F11C6CE22644D42C6AC4492EF8D39DC13168F \
	| tee /dev/stderr \
	| grep '0xA5CD6035332FA671' \
	| grep 'Andrew Haley'; \
	gpg --batch --verify openjdk.tgz.asc openjdk.tgz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	\
	mkdir -p "$JAVA_HOME"; \
	tar --extract \
	--file openjdk.tgz \
	--directory "$JAVA_HOME" \
	--strip-components 1 \
	--no-same-owner \
	; \
	rm openjdk.tgz*; \
	\
	# TODO strip "demo" and "man" folders?
	\
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
	# update "cacerts" bundle to use Debian's CA certificates (and make sure it stays up-to-date with changes to Debian's store)
	# see https://github.com/docker-library/openjdk/issues/327
	#     http://rabexc.org/posts/certificates-not-working-java#comment-4099504075
	#     https://salsa.debian.org/java-team/ca-certificates-java/blob/3e51a84e9104823319abeb31f880580e46f45a98/debian/jks-keystore.hook.in
	#     https://git.alpinelinux.org/aports/tree/community/java-cacerts/APKBUILD?id=761af65f38b4570093461e6546dcf6b179d2b624#n29
	{ \
	echo '#!/usr/bin/env bash'; \
	echo 'set -Eeuo pipefail'; \
	echo 'if ! [ -d "$JAVA_HOME" ]; then echo >&2 "error: missing JAVA_HOME environment variable"; exit 1; fi'; \
	# 8-jdk uses "$JAVA_HOME/jre/lib/security/cacerts" and 8-jre and 11+ uses "$JAVA_HOME/lib/security/cacerts" directly (no "jre" directory)
	echo 'cacertsFile=; for f in "$JAVA_HOME/lib/security/cacerts" "$JAVA_HOME/jre/lib/security/cacerts"; do if [ -e "$f" ]; then cacertsFile="$f"; break; fi; done'; \
	echo 'if [ -z "$cacertsFile" ] || ! [ -f "$cacertsFile" ]; then echo >&2 "error: failed to find cacerts file in $JAVA_HOME"; exit 1; fi'; \
	echo 'trust extract --overwrite --format=java-cacerts --filter=ca-anchors --purpose=server-auth "$cacertsFile"'; \
	} > /etc/ca-certificates/update.d/docker-openjdk; \
	chmod +x /etc/ca-certificates/update.d/docker-openjdk; \
	/etc/ca-certificates/update.d/docker-openjdk; \
	\
	# https://github.com/docker-library/openjdk/issues/331#issuecomment-498834472
	find "$JAVA_HOME/lib" -name '*.so' -exec dirname '{}' ';' | sort -u > /etc/ld.so.conf.d/docker-openjdk.conf; \
	ldconfig; \
	\
	# basic smoke test
	javac -version; \
	java -version
RUN unset JAVA_VERSION JAVA_BASE_URL JAVA_URL_VERSION

RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg \
	&& mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
	&& wget -q https://packages.microsoft.com/config/debian/10/prod.list \
	&& mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
	&& chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
	&& chown root:root /etc/apt/sources.list.d/microsoft-prod.list

RUN apt-get update \
	&& apt-get install apt-transport-https
RUN apt-get update \
	&& apt-get -y install dotnet-sdk-2.1 dotnet-runtime-2.1

RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Install git, process tools, lsb-release (common in install instructions for CLIs)
    && apt-get -y install procps lsb-release \
    #
    # Allow for a consistant java home location for settings - image is changing over time
    && if [ ! -d "/docker-java-home" ]; then ln -s "${JAVA_HOME}" /docker-java-home; fi \
    && if [ ! -d "/usr/local/default-jdk" ]; then ln -s "${JAVA_HOME}" /usr/local/default-jdk; fi \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
RUN echo "install.packages(c('repr', 'IRdisplay', 'RSentiment', 'IRkernel', 'igraph'), repos='https://mirror.las.iastate.edu/CRAN')" | R --vanilla
RUN echo "IRkernel::installspec(user = FALSE)" | R --vanilla
# RUN echo "setRepositories(ind=c(2)); source('https://bioconductor.org/biocLite.R'); biocLite('gRain',suppressUpdates=TRUE,ask=FALSE);biocLite('Rgraphviz',suppressUpdates=TRUE,ask=FALSE);" | R --vanilla
# Install R modules
RUN R -e "install.packages('rjson')" && \
	R -e "install.packages('XML')" && \
	R -e "install.packages('xml2')" && \
	R -e "install.packages('charlatan')" && \
	R -e "install.packages('httpuv')" && \
	R -e "install.packages('curl')" && \
	R -e "install.packages('httr')" && \
	R -e "install.packages('shiny')" && \
	R -e "install.packages('rmarkdown')" && \
	R -e "install.packages('knitr')" && \
	R -e "install.packages('caTools')" && \
	R -e "install.packages('writexl')" && \
	R -e "install.packages('rlist')" && \
	R -e "install.packages('tictoc')"&& \
	R -e "install.packages('kableExtra')"
# Install R packages
RUN R CMD javareconf && R -e "install.packages('rJava')" && \
	R -e "install.packages('odbc')" && \
	R -e "install.packages('RJDBC')"
RUN echo "PATH=$PATH" >> ~/.bashrc

RUN unset JAVA_VERSION JAVA_BASE_URL JAVA_URL_VERSION

# COPY ETC/Mikhail-Arkhipov.r-0.0.6.vsix /home/vscode
# COPY ETC/Ikuyadeu.r-1.1.8.vsix /home/vscode
# RUN code-server --install-extension /home/vscode/Mikhail-Arkhipov.r-0.0.6.vsix
# RUN code-server --install-extension /home/vscode/Ikuyadeu.r-1.1.8.vsix
# USER vscode
# RUN code-server --install-extension /home/vscode/Mikhail-Arkhipov.r-0.0.6.vsix
# RUN code-server --install-extension /home/vscode/Ikuyadeu.r-1.1.8.vsix
# USER root
# RUN rm -f /home/vscode/*.vsix