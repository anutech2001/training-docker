FROM oraclelinux:8-slim

RUN set -eux; \
    microdnf install \
    gzip \
    tar \
    \
    # jlink --strip-debug on 13+ needs objcopy: https://github.com/docker-library/openjdk/issues/351
    # Error: java.io.IOException: Cannot run program "objcopy": error=2, No such file or directory
    binutils \
    # java.lang.UnsatisfiedLinkError: /usr/java/openjdk-12/lib/libfontmanager.so: libfreetype.so.6: cannot open shared object file: No such file or directory
    # https://github.com/docker-library/openjdk/pull/235#issuecomment-424466077
    freetype fontconfig \
    ; \
    microdnf clean all

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

ENV JAVA_HOME /usr/java/openjdk-16
ENV PATH $JAVA_HOME/bin:$PATH

# https://jdk.java.net/
# >
# > Java Development Kit builds, from Oracle
# >
ENV JAVA_VERSION 16-ea+26

RUN set -eux; \
    \
    objdump="$(command -v objdump)"; \
    arch="$(objdump --file-headers "$objdump" | awk -F '[:,]+[[:space:]]+' '$1 == "architecture" { print $2 }')"; \
    # this "case" statement is generated via "update.sh"
    case "$arch" in \
    # arm64v8
    arm64 | aarch64) \
    downloadUrl=https://download.java.net/java/early_access/jdk16/26/GPL/openjdk-16-ea+26_linux-aarch64_bin.tar.gz; \
    downloadSha256=1e2fefe414a16aceeae6816b4e48b426e79bb647927a44bbfe4d692156096e74; \
    ;; \
    # amd64
    amd64 | i386:x86-64) \
    downloadUrl=https://download.java.net/java/early_access/jdk16/26/GPL/openjdk-16-ea+26_linux-x64_bin.tar.gz; \
    downloadSha256=e74300f3f770122358d768d45e181d29c710e8d41bbc4ab8e492929f2867347c; \
    ;; \
    # fallback
    *) echo >&2 "error: unsupported architecture: '$arch'"; exit 1 ;; \
    esac; \
    \
    curl -fL -o openjdk.tgz "$downloadUrl"; \
    echo "$downloadSha256 *openjdk.tgz" | sha256sum --strict --check -; \
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
    # https://github.com/oracle/docker-images/blob/a56e0d1ed968ff669d2e2ba8a1483d0f3acc80c0/OracleJava/java-8/Dockerfile#L17-L19
    ln -sfT "$JAVA_HOME" /usr/java/default; \
    ln -sfT "$JAVA_HOME" /usr/java/latest; \
    for bin in "$JAVA_HOME/bin/"*; do \
    base="$(basename "$bin")"; \
    [ ! -e "/usr/bin/$base" ]; \
    alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
    done; \
    \
    # https://github.com/docker-library/openjdk/issues/212#issuecomment-420979840
    # https://openjdk.java.net/jeps/341
    java -Xshare:dump; \
    \
    # see "update-ca-trust" script which creates/maintains this cacerts bundle
    rm -rf "$JAVA_HOME/lib/security/cacerts"; \
    ln -sT /etc/pki/ca-trust/extracted/java/cacerts "$JAVA_HOME/lib/security/cacerts"; \
    \
    # basic smoke test
    fileEncoding="$(echo 'System.out.println(System.getProperty("file.encoding"))' | jshell -s -)"; [ "$fileEncoding" = 'UTF-8' ]; rm -rf ~/.java; \
    javac --version; \
    java --version

# "jshell" is an interactive REPL for Java (see https://en.wikipedia.org/wiki/JShell)
CMD ["jshell"]