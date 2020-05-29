FROM openjdk:8u171-jdk-alpine3.8
LABEL maintainer="David Fry <david.fry@modusbox.com>"

# set user configurations
ARG USER=wso2carbon
ARG USER_ID=802
ARG USER_GROUP=wso2
ARG USER_GROUP_ID=802
ARG USER_HOME=/home/${USER}
# set dependant files directory
ARG FILES=./files
# set jdk configurations
ARG JDK=jdk1.8.0*
ARG JAVA_HOME=/usr/lib/jvm/default-jvm
# set wso2 product configurations
ARG WSO2_SERVER=wso2am
ARG WSO2_SERVER_VERSION=2.6.0
ARG WSO2_SERVER_DIST=${WSO2_SERVER}-${WSO2_SERVER_VERSION}
ARG WSO2_SERVER_HOME=${USER_HOME}/${WSO2_SERVER_DIST}

# install required packages
COPY ${FILES}/tzupdater.jar ${JAVA_HOME}/
COPY ${FILES}/ps_opt_p_enabled_for_alpine.sh /usr/bin/ps
# create a user group and a user

RUN apk add --update curl netcat-openbsd tzdata libxml2-utils openssl && \
    java -jar ${JAVA_HOME}/tzupdater.jar -v -f -l https://data.iana.org/time-zones/releases/tzdata2018e.tar.gz && \
    addgroup -S -g ${USER_GROUP_ID} ${USER_GROUP} && \
    adduser -S -h ${USER_HOME} -G ${USER_GROUP} -u ${USER_ID} ${USER} && \
    mkdir -p /etc/.java/.systemPrefs ${USER_HOME}/wso2-tmp/server/ && chown -R wso2carbon:wso2 ${USER_HOME} /etc/.java/.systemPrefs ${JAVA_HOME} && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* 

# copy the wso2 product distributions to user's home directory
COPY --chown=wso2carbon:wso2 ${FILES}/${WSO2_SERVER_DIST} ${WSO2_SERVER_HOME}

# copy mysql connector jar to the server as a third party library
COPY --chown=wso2carbon:wso2 ${FILES}/lib/* ${WSO2_SERVER_HOME}/repository/components/lib/
COPY --chown=wso2carbon:wso2 ${FILES}/dropins/* ${WSO2_SERVER_HOME}/repository/components/dropins/
COPY --chown=wso2carbon:wso2 ${FILES}/wars/*.war ${WSO2_SERVER_HOME}/repository/deployment/server/webapps/

# copy init script to user home
COPY --chown=wso2carbon:wso2 ${FILES}/init.sh ${USER_HOME}/

# set the user and work directory
USER ${USER_ID}
WORKDIR ${USER_HOME}

# set environment variables
ENV JAVA_HOME=${JAVA_HOME} \
    PATH=$JAVA_HOME/bin:$PATH \
    WSO2_SERVER_HOME=${WSO2_SERVER_HOME} \
    WORKING_DIRECTORY=${USER_HOME} \
    JAVA_OPTS="-Djava.util.prefs.systemRoot=${USER_HOME}/.java -Djava.util.prefs.userRoot=${USER_HOME}/.java/.userPrefs"

# expose ports
EXPOSE 9443 8243

ENTRYPOINT ${WORKING_DIRECTORY}/init.sh

# MOUNTS -: new persisted mounts required
# 1) /home/wso2carbon/wso2am-2.6.0/repository/deployment/server/synapse-configs/default/api
# 2) /home/wso2carbon/wso2am-2.6.0/repository/deployment/server/synapse-configs/default/endpoints