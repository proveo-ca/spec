FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="Proveo"
LABEL description="Spec Build Container"

RUN apk add --no-cache bash graphviz ttf-droid ttf-dejavu

ARG PLANTUML_VERSION=1.2024.3
RUN wget "https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar" \
    -O /opt/plantuml.jar

COPY internal-build.sh /usr/local/bin/entrypoint.sh
# Ensure line endings are Unix-style (LF)
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /data
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
