FROM mrsono0/devremotecontainers:python3.7.5  as r-devel

ARG BUILD_DATE
ENV TERM=xterm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	bash-completion \
	ca-certificates \
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
	&& apt-get install -y --no-install-recommends $BUILDDEPS \
	&& cd tmp/ \
	## Download source code
	&& svn co https://svn.r-project.org/R/trunk R-devel \
	## Extract source code
	&& cd R-devel \
	## Get source code of recommended packages
	&& ./tools/rsync-recommended \
	## Set compiler flags
	&& R_PAPERSIZE=letter \
	R_BATCHSAVE="--no-save --no-restore" \
	R_BROWSER=xdg-open \
	PAGER=/usr/bin/pager \
	PERL=/usr/bin/perl \
	R_UNZIPCMD=/usr/bin/unzip \
	R_ZIPCMD=/usr/bin/zip \
	R_PRINTCMD=/usr/bin/lpr \
	LIBnn=lib \
	AWK=/usr/bin/awk \
	CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
	CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
	## Configure options
	./configure --enable-R-shlib \
	--enable-memory-profiling \
	--with-readline \
	--with-blas \
	--with-tcltk \
	--disable-nls \
	--with-recommended-packages \
	## Build and install
	&& make \
	&& make install \
	## Add a default CRAN mirror
	&& echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site \
	## Add a library directory (for user-installed packages)
	&& mkdir -p /usr/local/lib/R/site-library \
	&& chown root:staff /usr/local/lib/R/site-library \
	&& chmod g+wx /usr/local/lib/R/site-library \
	## Fix library path
	&& echo "R_LIBS_USER='/usr/local/lib/R/site-library'" >> /usr/local/lib/R/etc/Renviron \
	&& echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron \
	## install packages from date-locked MRAN snapshot of CRAN
	&& [ -z "$BUILD_DATE" ] && BUILD_DATE=$(TZ="America/Los_Angeles" date -I) || true \
	&& MRAN=https://mran.microsoft.com/snapshot/${BUILD_DATE} \
	&& echo MRAN=$MRAN >> /etc/environment \
	&& export MRAN=$MRAN \
	## MRAN becomes default only in versioned images
	## Use littler installation scripts
	# && Rscript -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')" \
	&& ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r \
	## TEMPORARY WORKAROUND to get more robust error handling for install2.r prior to littler update
	&& curl -O /usr/local/bin/install2.r https://github.com/eddelbuettel/littler/raw/master/inst/examples/install2.r \
	# && chmod +x /usr/local/bin/install2.r \
	## Clean up from R source install
	&& cd / \
	&& rm -rf /tmp/* \
	&& apt-get remove --purge -y $BUILDDEPS \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& rm -rf /var/lib/apt/lists/*

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

RUN echo "install.packages(c('repr', 'IRdisplay', 'RSentiment', 'IRkernel', 'igraph'), repos='https://mirror.las.iastate.edu/CRAN')" | R --vanilla
RUN echo "IRkernel::installspec(user = FALSE)" | R --vanilla
# RUN echo "setRepositories(ind=c(2)); source('https://bioconductor.org/biocLite.R'); biocLite('gRain',suppressUpdates=TRUE,ask=FALSE);biocLite('Rgraphviz',suppressUpdates=TRUE,ask=FALSE);" | R --vanilla
# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

FROM r-devel

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	# utilities for keeping Debian and OpenJDK CA certificates in sync
	ca-certificates p11-kit \
	; \
	rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/local/openjdk-11
ENV PATH /usr/local/bin:/usr/local/openjdk-11/bin:$PATH

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
# Install R packages
RUN R CMD javareconf && R -e "install.packages('rJava')" && \
	R -e "install.packages('odbc')" && \
	R -e "install.packages('RJDBC')"
RUN apt-get clean
RUN echo "PATH=$PATH" >> ~/.bashrc
# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

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
	&& apt-get -y install dotnet-sdk-3.0 dotnet-runtime-3.0

# RUN apt-get update \
#     && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \

# COPY ETC/Mikhail-Arkhipov.r-0.0.6.vsix /home/vscode
# RUN code-server --install-extension /home/vscode/Mikhail-Arkhipov.r-0.0.6.vsix
# USER vscode
# RUN code-server --install-extension /home/vscode/Mikhail-Arkhipov.r-0.0.6.vsix
# USER root
# RUN rm -f /home/vscode/*.vsix