# jboss/base-jdk:8
FROM openshift/base-centos7

# TODO: Put the maintainer name in the image metadata
# LABEL maintainer="Your Name <your@email.com>"

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV BUILDER_VERSION 1.0

ENV JETTY_VERSION 9.4.9.v20180320
ENV DEPLOY_DIR /deployments
ENV JAVA /usr/bin/java

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building Jetty Not for Production" \
      io.k8s.display-name="Jetty Builder 1.0.0" \
      io.openshift.expose-services="8080:http" \
    io.openshift.tags="builder,Jetty,Swannie"

# TODO: Install required packages here:
# RUN yum install -y ... && yum clean all -y
RUN INSTALL_PKGS="tar unzip bc which lsof java-1.8.0-openjdk java-1.8.0-openjdk-devel" && \
    yum install -y --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y && \
    (curl -v https://www.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/local/bin/mvn && \
    mkdir -p $HOME/.m2 && \
    mkdir -p /opt/s2i/destination

# Install JETTY
RUN curl http://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${JETTY_VERSION}/jetty-distribution-${JETTY_VERSION}.tar.gz -o /tmp/jetty.tar.gz && \
    cd /usr/local && tar zxvf /tmp/jetty.tar.gz && \
    ln -s /usr/local/jetty-distribution-${JETTY_VERSION} /usr/local/jetty && \
    chgrp -R 0 /usr/local/jetty-distribution-${JETTY_VERSION} && \
    chmod -R g=u /usr/local/jetty-distribution-${JETTY_VERSION} && \
    rm /tmp/jetty.tar.gz

# TODO (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /usr/local/jetty/webapps/

# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./s2i/bin/ /usr/libexec/s2i

# TODO: Drop the root user and make the content of /opt/app-root owned by user 1001
# RUN chown -R 1001:1001 /opt/jetty
COPY run-java.sh /usr/local
RUN chmod 755 /usr/local/run-java.sh

ADD deploy-and-run.sh /usr/local/jetty/bin/
ADD jetty-logging.xml /usr/local/jetty/etc/
RUN chmod a+x /usr/local/jetty/bin/deploy-and-run.sh

# This default user is created in the openshift/base-centos7 image
USER 1001

ENV JETTY_HOME /usr/local/jetty
ENV PATH $PATH:$JETTY_HOME/bin


# TODO: Set the default port for applications built using this image
EXPOSE 8080

# TODO: Set the default CMD for the image
CMD ["/usr/libexec/s2i/usage"]
