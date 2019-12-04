FROM mrsono0/devremotecontainers:anaconda3 as openjdk
# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH /usr/local/bin:$PATH
ENV JAVA_HOME /usr/local/openjdk-11
ENV PATH ${JAVA_HOME}/bin:$PATH

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	# utilities for keeping Debian and OpenJDK CA certificates in sync
	ca-certificates p11-kit \
	wget unzip sudo \
    openssl \
	net-tools \
	git \
	locales \
	sudo \
	dumb-init \
	curl \
	; \
	rm -rf /var/lib/apt/lists/*

# backwards compatibility shim
RUN { echo '#/bin/sh'; echo 'echo "$JAVA_HOME"'; } > /usr/local/bin/docker-java-home && chmod +x /usr/local/bin/docker-java-home && [ "$JAVA_HOME" = "$(docker-java-home)" ]

# https://adoptopenjdk.net/upstream.html
ENV JAVA_VERSION 11.0.5
ENV JAVA_BASE_URL https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/download/jdk-11.0.5%2B10/OpenJDK11U-jdk_
ENV JAVA_URL_VERSION 11.0.5_10
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
	javac --version; \
	java --version
RUN if [ ! -d "/usr/local/default-jdk" ]; then ln -s "${JAVA_HOME}" /usr/local/default-jdk; fi
## https://github.com/SpencerPark/IJava
RUN wget https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip
RUN mv ijava-1.3.0.zip /usr/local/; cd /usr/local; unzip ijava-1.3.0.zip; python /usr/local/install.py --sys-prefix; rm -r java install.py ijava-1.3.0.zip

ARG MAVEN_VERSION=3.6.2
ARG USER_HOME_DIR="/root"
ARG SHA=d941423d115cd021514bfd06c453658b1b3e39e6240969caf4315ab7119a77299713f14b620fb2571a264f8dff2473d8af3cb47b05acf0036fc2553199a5c1ee
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN apt-get update && \
    apt-get install -y \
      curl procps \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# COPY ETC/mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh
# COPY ETC/settings-docker.xml /usr/share/maven/ref/
COPY ETC/jupyterlab.sh /usr/local/bin

# ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]

RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Install git, process tools, lsb-release (common in install instructions for CLIs)
    && apt-get -y install procps lsb-release \
    #
    # Allow for a consistant java home location for settings - image is changing over time
    && if [ ! -d "/docker-java-home" ]; then ln -s "${JAVA_HOME}" /docker-java-home; fi \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN wget http://apache.mirror.cdnetworks.com/tomcat/tomcat-9/v9.0.29/bin/apache-tomcat-9.0.29.tar.gz
# RUN wget http://www-us.apache.org/dist/tomcat/tomcat-9/v9.0.29/bin/apache-tomcat-9.0.29.tar.gz
RUN tar xzf apache-tomcat-9.0.29.tar.gz; rm -rf apache-tomcat-9.0.29.tar.gz
RUN mv apache-tomcat-9.0.29 /usr/local/tomcat9; chmod -R 775 /usr/local/tomcat9/; chown -R root:vscode /usr/local/tomcat9

ENV CATALINA_HOME /usr/local/tomcat9
ENV PATH ${CATALINA_HOME}/bin:$PATH
ENV TOMCAT_NATIVE_LIBDIR ${CATALINA_HOME}/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${TOMCAT_NATIVE_LIBDIR}

FROM openjdk as nodejs

ENV NODE_VERSION 12.13.0

RUN buildDeps='xz-utils' \
	&& ARCH= && dpkgArch="$(dpkg --print-architecture)" \
	&& case "${dpkgArch##*-}" in \
	amd64) ARCH='x64';; \
	ppc64el) ARCH='ppc64le';; \
	s390x) ARCH='s390x';; \
	arm64) ARCH='arm64';; \
	armhf) ARCH='armv7l';; \
	i386) ARCH='x86';; \
	*) echo "unsupported architecture"; exit 1 ;; \
	esac \
	&& set -ex \
	&& apt-get update && apt-get install -y ca-certificates curl wget gnupg dirmngr $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& for key in \
	94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
	FD3A5288F042B6850C66B31F09FE44734EB7990E \
	71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
	DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
	C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
	B9AE9905FFD7803F25714661B63B535A4C206CA9 \
	77984A986EBC2AA786BC0F66B01FBB92821C587A \
	8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
	4ED778F539E3634C779C87C6D7062848A1AB005C \
	A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
	B9E2F5981AA6E0CD28160D9FF13993A75599653C \
	; do \
	gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
	gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
	gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
	done \
	&& curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
	&& curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
	&& grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
	&& tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
	&& rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.19.1

RUN set -ex \
	&& for key in \
	6A010C5166006599AA17F08146C2130DFD2497F5 \
	; do \
	gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
	gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
	gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
	done \
	&& curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
	&& curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
	&& gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
	&& mkdir -p /opt \
	&& tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
	&& ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
	&& ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
	&& rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

## https://dydals5678.tistory.com/89
## https://github.com/yunabe/tslab
RUN npm install --silent --save-dev -g \
        gulp-cli \
        typescript \
		@babel/node \
		@babel/core \
		tslab
RUN tslab install
RUN jupyter kernelspec list

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \ 
    #
    # Verify git and needed tools are installed
    && apt-get install -y git procps \
    #
    # Install eslint globally
    && npm install -g eslint \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

FROM nodejs as r
ENV TERM=xterm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	ed \
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

FROM r as r-devel
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	bash-completion \
	ca-certificates \
    software-properties-common \
    apt-transport-https \
	ccache \
	devscripts \
	file \
	fonts-texgyre \
	g++ \
	gfortran \
	gsfonts \
	libblas-dev \
	libbz2-1.0 \
	libcurl4 \
	libicu63 \
	libjpeg62-turbo \
	libopenblas-dev \
	libpangocairo-1.0-0 \
	libpcre3 \
	libpng16-16 \
	libreadline7 \
	libtiff5 \
	liblzma5 \
	locales \
	make \
	unzip \
	zip \
	zlib1g \
	# && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	# && locale-gen en_US.utf8 \
	# && /usr/sbin/update-locale LANG=en_US.UTF-8 \
	&& BUILDDEPS="curl \
	libbz2-dev \
	libcairo2-dev \
	libcurl4-openssl-dev \
	libpango1.0-dev \
	libjpeg-dev \
	libicu-dev \
	libpcre3-dev \
	libpng-dev \
	libreadline-dev \
	libtiff5-dev \
	liblzma-dev \
	libx11-dev \
	libxt-dev \
	perl \
	rsync \
	subversion tcl8.6-dev \
	tk8.6-dev \
	texinfo \
	texlive-extra-utils \
	texlive-fonts-recommended \
	texlive-fonts-extra \
	texlive-latex-recommended \
	x11proto-core-dev \
	xauth \
	xfonts-base \
	xvfb \
	zlib1g-dev" \
	# && apt-get install -y --no-install-recommends $BUILDDEPS \
	# && cd tmp/ \
	# ## Download source code
	# && svn co https://svn.r-project.org/R/trunk R-devel \
	# ## Extract source code
	# && cd R-devel \
	# ## Get source code of recommended packages
	# && ./tools/rsync-recommended \
	# ## Set compiler flags
	# && R_PAPERSIZE=letter \
	# R_BATCHSAVE="--no-save --no-restore" \
	# R_BROWSER=xdg-open \
	# PAGER=/usr/bin/pager \
	# PERL=/usr/bin/perl \
	# R_UNZIPCMD=/usr/bin/unzip \
	# R_ZIPCMD=/usr/bin/zip \
	# R_PRINTCMD=/usr/bin/lpr \
	# LIBnn=lib \
	# AWK=/usr/bin/awk \
	# CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
	# CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
	# ## Configure options
	# ./configure --enable-R-shlib \
	# --enable-memory-profiling \
	# --with-readline \
	# --with-blas \
	# --with-tcltk \
	# --disable-nls \
	# --with-recommended-packages \
	# ## Build and install
	# && make \
	# && make install \
	# ## Add a default CRAN mirror
	# && echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site \
	# ## Add a library directory (for user-installed packages)
	# && mkdir -p /usr/local/lib/R/site-library \
	# && chown root:staff /usr/local/lib/R/site-library \
	# && chmod g+wx /usr/local/lib/R/site-library \
	# ## Fix library path
	# && echo "R_LIBS_USER='/usr/local/lib/R/site-library'" >> /usr/local/lib/R/etc/Renviron \
	# && echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron \
	# ## install packages from date-locked MRAN snapshot of CRAN
	# && [ -z "$BUILD_DATE" ] && BUILD_DATE=$(TZ="America/Los_Angeles" date -I) || true \
	# && MRAN=https://mran.microsoft.com/snapshot/${BUILD_DATE} \
	# && echo MRAN=$MRAN >> /etc/environment \
	# && export MRAN=$MRAN \
	# ## MRAN becomes default only in versioned images
	# ## Use littler installation scripts
	# && Rscript -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')" \
	# # && ./R -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')" \
	# && ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
	# && ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	# && ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r \
	# ## TEMPORARY WORKAROUND to get more robust error handling for install2.r prior to littler update
	# # && curl -O /usr/local/bin/install2.r https://github.com/eddelbuettel/littler/raw/master/inst/examples/install2.r \
	# # && chmod +x /usr/local/bin/install2.r \
	# ## Clean up from R source install
	&& cd / \
	&& rm -rf /tmp/* \
	&& apt-get remove --purge -y $BUILDDEPS \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& rm -rf /var/lib/apt/lists/*

# Install R modules
# RUN R -e "install.packages('rjson')" && \
# 	R -e "install.packages('XML')" && \
# 	R -e "install.packages('xml2')" && \
# 	R -e "install.packages('charlatan')" && \
# 	R -e "install.packages('httpuv')" && \
# 	R -e "install.packages('curl')" && \
# 	R -e "install.packages('httr')" && \
# 	R -e "install.packages('shiny')" && \
# 	R -e "install.packages('rmarkdown')" && \
# 	R -e "install.packages('knitr')" && \
# 	R -e "install.packages('caTools')" && \
# 	R -e "install.packages('writexl')" && \
# 	R -e "install.packages('rlist')" && \
# 	R -e "install.packages('tictoc')" && \
#     # R -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')" && \
# 	R -e "install.packages('kableExtra')"
RUN apt-get clean

FROM r-devel as vscode-server
RUN pip install --upgrade pip
RUN pip install 2to3 imageio \
    tensorflow-datasets urllib3
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

RUN apt-get install -y zsh neovim git git-lfs
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
RUN echo "source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
RUN echo "source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
RUN curl -sLf https://spacevim.org/install.sh | bash
RUN curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | bash
RUN chsh -s `which zsh`

#CleanUp
RUN ldconfig && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

FROM vscode-server as ai
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    GIT_CLONE="git clone --depth 10" && \

    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \

    apt-get update && \

# ==================================================================
# tools
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        wget \
        git \
        vim \
        libssl-dev \
        curl \
        unzip \
        # unrar \
        && \

    $GIT_CLONE https://github.com/Kitware/CMake ~/cmake && \
    cd ~/cmake && \
    ./bootstrap && \
    make -j"$(nproc)" install && \

# ==================================================================
# darknet
# ------------------------------------------------------------------

    $GIT_CLONE https://github.com/pjreddie/darknet.git ~/darknet && \
    cd ~/darknet && \
    sed -i 's/GPU=0/GPU=0/g' ~/darknet/Makefile && \
    sed -i 's/CUDNN=0/CUDNN=0/g' ~/darknet/Makefile && \
    make -j"$(nproc)" && \
    cp ~/darknet/include/* /usr/local/include && \
    cp ~/darknet/*.a /usr/local/lib && \
    cp ~/darknet/*.so /usr/local/lib && \
    cp ~/darknet/darknet /usr/local/bin && \

# ==================================================================
# tensorflow
# ------------------------------------------------------------------

    $PIP_INSTALL \
        tensorflow \
        && \

# ==================================================================
# keras
# ------------------------------------------------------------------

    $PIP_INSTALL \
        h5py \
        keras \
        && \

# ==================================================================
# opencv
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        libatlas-base-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        && \

    $GIT_CLONE --branch 4.1.2 https://github.com/opencv/opencv ~/opencv && \
    mkdir -p ~/opencv/build && cd ~/opencv/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_IPP=OFF \
          -D WITH_CUDA=OFF \
          -D WITH_OPENCL=OFF \
          -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_EXAMPLES=OFF \
          .. && \
    make -j"$(nproc)" install && \
    ln -s /usr/local/include/opencv4/opencv2 /usr/local/include/opencv2 && \

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------

    ldconfig && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*
