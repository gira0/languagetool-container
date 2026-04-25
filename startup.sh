#!/bin/sh

DIR="/languagetool"
if [ -d "$DIR" ]; then
  echo "${DIR} found! running with ngram data"
  java -cp /opt/languagetool/languagetool-server.jar org.languagetool.server.HTTPServer --languageModel /languagetool --port 8080 --allow-origin '*' --public

else
  echo "${DIR} not found, running without ngram data"
  # Debugging: print java home and security files to help diagnose java.security load errors
  echo "DEBUG: JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk}"
  echo "DEBUG: id:" $(id) || true
  echo "DEBUG: ls -ld ${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk} and security dir (if present)"
  ls -ld ${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk} || true
  ls -ld ${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk}/conf || true
  ls -ld ${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk}/conf/security || true
  find ${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk} -maxdepth 4 -name java.security -exec ls -l {} \; -exec sed -n '1,40p' {} \; || true
  java -cp /opt/languagetool/languagetool-server.jar org.languagetool.server.HTTPServer --port 8080 --allow-origin '*' --public

fi
