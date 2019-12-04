FROM mrsono0/devremotecontainers:python3.7.5

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	curl zip gzip unzip wget \
	; \
	apt-get clean; \
	rm -rf /var/lib/apt/lists/*

ENV JAVA_FILE jdk-11.0.5_linux-x64_bin.tar.gz
COPY ETC/${JAVA_FILE} /usr/local/
RUN cd /usr/local; tar -zxvf ${JAVA_FILE}; rm /usr/local/${JAVA_FILE}; ls -al; cd /

ENV JAVA_HOME /usr/local/jdk-11.0.5
ENV PATH $JAVA_HOME/bin:$PATH
# RUN update-alternatives --config java

	# basic smoke test
RUN	javac -version; \
	java -version

## https://github.com/SpencerPark/IJava
RUN wget https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip
RUN mv ijava-1.3.0.zip /usr/local/; cd /usr/local; unzip ijava-1.3.0.zip; python /usr/local/install.py --sys-prefix; rm -r java install.py

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

# ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]

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