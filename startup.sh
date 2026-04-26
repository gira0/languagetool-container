#!/bin/sh

set -eu

PORT=${PORT:-8080}
JAVA_OPTS=${JAVA_OPTS:-}
DIR="/languagetool"
APP_JAR="/opt/languagetool/languagetool-server.jar"

if [ -d "$DIR" ]; then
  echo "${DIR} found! running with ngram data"
  exec java $JAVA_OPTS -cp "$APP_JAR" org.languagetool.server.HTTPServer --languageModel "$DIR" --port "$PORT" --allow-origin '*' --public
fi

echo "${DIR} not found, running without ngram data"
exec java $JAVA_OPTS -cp "$APP_JAR" org.languagetool.server.HTTPServer --port "$PORT" --allow-origin '*' --public
