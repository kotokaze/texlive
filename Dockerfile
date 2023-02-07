### base stage
ARG VARIANT=bullseye
FROM buildpack-deps:${VARIANT}-curl as base

ARG SCHEME=full
ARG DOCFILES=0
ARG SRCFILES=0

ENV \
  DEBIAN_FRONTEND=noninteractive \
  SCHEME=${SCHEME} \
  DOCFILES=${DOCFILES} \
  SRCFILES=${SRCFILES} \
  NOPERLDOC=1

# Install dependencies
RUN apt update && apt install -qy --no-install-recommends \
  git unzip \
  make fontconfig perl default-jre libgetopt-long-descriptive-perl libdigest-perl-md5-perl libncurses5 libncurses6 \
  libunicode-linebreak-perl libfile-homedir-perl libyaml-tiny-perl \
  ghostscript \
  libsm6 \
  python3 python3-pygments python-is-python3 \
  gnuplot-nox \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /var/cache/apt/

### builder stage
FROM base as builder
WORKDIR /tmp

ENV \
  TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \
  TEXLIVE_INSTALL_NO_DISKCHECK=1

# Create profile
COPY texlive.installation.profile .
RUN sed -i \
  -re "s|(selected_scheme\ scheme-)full|\1"${SCHEME}"|" \
  -re "s|(tlpdbopt_install_docfiles\ )0|\1"${DOCFILES}"|" \
  -re "s|(tlpdbopt_install_srcfiles\ )0|\1"${SRCFILES}"|" \
  texlive.installation.profile \
  && cat texlive.installation.profile

# Compile TeX Live (Use local repo if available)
COPY texliv[e] texlive/
RUN if [ ! -d texlive ] \
  ;then \
  echo "Using online installer" \
  && mkdir texlive  \
  && curl -sSLO https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
  && zcat install-tl-unx.tar.gz | tar -vx --strip-components=1 -C texlive \
  ;fi \
  && cd texlive \
  && perl ./install-tl -profile ../texlive.installation.profile --no-interaction

### final stage
FROM base
WORKDIR /tmp

# Install
COPY --from=builder /opt/texlive/ /opt/texlive/

# Create dummy package with equivs and generate cache
RUN apt update && apt install -qy --no-install-recommends equivs \
  && curl https://tug.org/texlive/files/debian-equivs-2022-ex.txt -o texlive-local \
  && sed -i -e "s/2022/9999/" -e "/Depends: freeglut3/d" texlive-local \
  && equivs-build texlive-local \
  && dpkg -i texlive-local_9999.99999999-1_all.deb \
  && apt install -qy --no-install-recommends \
  && rm -rf ./*texlive* \
  && apt purge -qy equivs \
  && apt autoremove -qy --purge \
  && rm -rf /var/lib/apt/lists/* \
  && apt clean \
  && rm -rf /var/cache/apt/

# Add to path and generate cache
RUN $(find /opt/texlive -name tlmgr) path add \
  && (luaotfload-tool -u || true) \
  && (mtxrun --generate || true) \
  && (cp "$(find /usr/local/texlive -name texlive-fontconfig.conf)" /etc/fonts/conf.d/09-texlive-fonts.conf || true) \
  && fc-cache -fsv

WORKDIR /root
ENTRYPOINT [ "/bin/bash" ]
