FROM mrsono0/devremotecontainers:python3.7.5

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	# utilities for keeping Debian and OpenJDK CA certificates in sync
	unzip zip gzip p11-kit \
	; \
	rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/java/openjdk-13
ENV PATH $JAVA_HOME/bin:$PATH

# backwards compatibility shim
RUN { echo '#/bin/sh'; echo 'echo "$JAVA_HOME"'; } > /usr/local/bin/docker-java-home && chmod +x /usr/local/bin/docker-java-home && [ "$JAVA_HOME" = "$(docker-java-home)" ]

# https://jdk.java.net/
ENV JAVA_VERSION 13.0.1
ENV JAVA_URL https://download.java.net/java/GA/jdk13.0.1/cec27d702aa74d5a8630c65ae61e4305/9/GPL/openjdk-13.0.1_linux-x64_bin.tar.gz
ENV JAVA_SHA256 2e01716546395694d3fad54c9b36d1cd46c5894c06f72d156772efbcf4b41335

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	wget \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	wget -O openjdk.tgz "$JAVA_URL"; \
	echo "$JAVA_SHA256 */openjdk.tgz" | sha256sum -c -; \
	\
	mkdir -p "$JAVA_HOME"; \
	tar --extract \
	--file openjdk.tgz \
	--directory "$JAVA_HOME" \
	--strip-components 1 \
	--no-same-owner \
	; \
	rm openjdk.tgz; \
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
	# https://github.com/docker-library/openjdk/issues/212#issuecomment-420979840
	# https://openjdk.java.net/jeps/341
	java -Xshare:dump; \
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
# COPY ETC/jupyterlab.sh /usr/local/bin

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

RUN unset JAVA_VERSION JAVA_BASE_URL JAVA_URL_VERSION

COPY ETC/vscjava.vscode-java-pack-0.8.1.vsix /home/vscode
COPY ETC/redhat.java-0.53.1.vsix /home/vscode
COPY ETC/vscjava.vscode-java-debug-0.23.0.vsix /home/vscode
COPY ETC/vscjava.vscode-java-dependency-0.6.0.vsix /home/vscode
COPY ETC/vscjava.vscode-java-test-0.21.0.vsix /home/vscode
COPY ETC/vscjava.vscode-maven-0.20.0.vsix /home/vscode

COPY ETC/adashen.vscode-tomcat-0.11.1.vsix /home/vscode

COPY ETC/Pivotal.vscode-boot-dev-pack-0.0.8.vsix /home/vscode
COPY ETC/Pivotal.vscode-spring-boot-1.13.0.vsix /home/vscode
COPY ETC/vscjava.vscode-spring-boot-dashboard-0.1.6.vsix /home/vscode
COPY ETC/vscjava.vscode-spring-initializr-0.4.6.vsix /home/vscode

RUN code-server --install-extension /home/vscode/vscjava.vscode-java-pack-0.8.1.vsix
RUN code-server --install-extension /home/vscode/redhat.java-0.53.1.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-java-debug-0.23.0.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-java-dependency-0.6.0.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-java-test-0.21.0.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-maven-0.20.0.vsix

RUN code-server --install-extension /home/vscode/adashen.vscode-tomcat-0.11.1.vsix

RUN code-server --install-extension /home/vscode/Pivotal.vscode-boot-dev-pack-0.0.8.vsix
RUN code-server --install-extension /home/vscode/Pivotal.vscode-spring-boot-1.13.0.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-spring-boot-dashboard-0.1.6.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-spring-initializr-0.4.6.vsix
USER vscode
RUN code-server --install-extension /home/vscode/vscjava.vscode-java-pack-0.8.1.vsix
RUN code-server --install-extension /home/vscode/redhat.java-0.53.1.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-java-debug-0.23.0.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-java-dependency-0.6.0.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-java-test-0.21.0.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-maven-0.20.0.vsix

RUN code-server --install-extension /home/vscode/adashen.vscode-tomcat-0.11.1.vsix

RUN code-server --install-extension /home/vscode/Pivotal.vscode-boot-dev-pack-0.0.8.vsix
RUN code-server --install-extension /home/vscode/Pivotal.vscode-spring-boot-1.13.0.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-spring-boot-dashboard-0.1.6.vsix
RUN code-server --install-extension /home/vscode/vscjava.vscode-spring-initializr-0.4.6.vsix
USER root
RUN rm -f /home/vscode/*.vsix