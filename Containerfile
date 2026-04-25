ARG LT_VER=6.4
FROM registry.access.redhat.com/ubi10/ubi:10.1 as stage1
ARG LT_VER

RUN dnf -y install git maven unzip java-17-openjdk-headless && dnf clean all
RUN git clone --depth 1 https://github.com/languagetool-org/languagetool.git -b v${LT_VER} /opt/languagetool/
WORKDIR /opt/languagetool/

# Build LanguageTool (skip tests to speed up CI)
RUN mvn -q --projects languagetool-standalone --also-make package -DskipTests

FROM registry.access.redhat.com/ubi10/ubi:10.1 as stage2
ARG LT_VER

RUN dnf -y install java-17-openjdk-headless && dnf clean all

COPY --from=stage1 /opt/languagetool/languagetool-standalone/target/LanguageTool-${LT_VER}/LanguageTool-${LT_VER}/ /opt/languagetool/
COPY --chmod=755 startup.sh /opt/languagetool/startup.sh

RUN useradd -r -s /sbin/nologin lang && chown -R lang:lang /opt/languagetool
USER lang

EXPOSE 8080/tcp
CMD ["/opt/languagetool/startup.sh"]
