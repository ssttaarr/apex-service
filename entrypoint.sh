#!/bin/bash

#exit on error
set -euo pipefail
trap 'exit 130' INT


# substitute the param file with current environment variables
cat /ords_params.properties.tmpl | envsubst > $ORDS_PARAMS

echo test database
logon="${SYS_USER}/${SYS_PASSWORD}@//${DB_HOSTNAME}:${DB_PORT}/${DB_SERVICE} as SYSDBA"
echo "SELECT * FROM DUAL;
exit"| sql -L $logon

# run ORDS simple install with the generated param file 
echo simple install ORDS
java -jar $ORDS_HOME/ords.war install simple --parameterFile $ORDS_PARAMS 

USER_ID=${TOMCAT_USER_ID:-1000}
GROUP_ID=${TOMCAT_GROUP_ID:-1000}

###
# Tomcat user
###
groupadd -r tomcat -g ${GROUP_ID} && \
useradd -u ${USER_ID} -g tomcat -d ${CATALINA_HOME} -s /sbin/nologin \
	-c "Tomcat user" tomcat

chown -R tomcat:tomcat "${CATALINA_HOME}" "${APEX_HOME}" "${ORDS_HOME}"

echo  Start tomcat 
exec gosu tomcat catalina.sh run
