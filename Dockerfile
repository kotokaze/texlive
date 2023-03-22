# syntax=docker/dockerfile:1

ARG VARIANT=bullseye
FROM buildpack-deps:${VARIANT}-curl
WORKDIR /tmp

ARG SCHEME=full
ARG DOCFILES=0
ARG SRCFILES=0

ENV \
  LANG=C.UTF-8 LC_ALL=C.UTF-8 \
  DEBIAN_FRONTEND=noninteractive \
  SCHEME=${SCHEME} \
  DOCFILES=${DOCFILES} \
  SRCFILES=${SRCFILES} \
  NOPERLDOC=1 \
  TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \
  TEXLIVE_INSTALL_NO_DISKCHECK=1

# Install dependencies
RUN apt update && apt install -qy --no-install-recommends \
  git unzip \
  make fontconfig perl default-jre libgetopt-long-descriptive-perl libdigest-perl-md5-perl libncurses5 libncurses6 \
  libunicode-linebreak-perl libfile-homedir-perl libyaml-tiny-perl \
  ghostscript \
  libsm6 \
  python3 python3-pygments python-is-python3 \
  gnuplot-nox \
  equivs \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /var/cache/apt/

# Create profile
COPY --link texlive.installation.profile .
RUN sed -i \
  -e "/^selected_scheme\ scheme-/s/full/"${SCHEME}"/" \
  -e "/^tlpdbopt_install_docfiles\ /s/0/"${DOCFILES}"/" \
  -e "/^tlpdbopt_install_srcfiles\ /s/0/"${SRCFILES}"/" \
  texlive.installation.profile \
  && cat texlive.installation.profile

# Compile TeX Live (Use local repo if available)
COPY --link texliv[e] texlive/
RUN if [ ! -d texlive ] \
  ;then \
  echo "Using online installer" \
  && mkdir texlive  \
  && curl -sSLO https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
  && zcat install-tl-unx.tar.gz | tar -vx --strip-components=1 -C texlive \
  ;fi \
  && cd texlive \
  && perl ./install-tl -profile ../texlive.installation.profile --no-interaction \
  && mv TEXLIVE_* ../ \
  && cd .. \
  && rm -rf texlive

# Create dummy package with equivs and generate cache
RUN RELEASE=$(find -name 'TEXLIVE_*' -print0 | sed -e s/[^0-9]//g) \
  && (curl -sLf "https://tug.org/texlive/files/debian-equivs-"${RELEASE}"-ex.txt" || curl -sSLf "https://tug.org/texlive/files/debian-equivs-"$((${RELEASE}-1))"-ex.txt" ) \
  | sed -e "/^Version:\ /s/"${RELEASE}"/9999/" -e "/^Version:\ /s/"$((${RELEASE}-1))"/9999/" -e "/^Depends:\ freeglut3$/d" \
  | equivs-build - \
  && dpkg -i texlive-local_9999.99999999-1_all.deb \
  && apt install -qy --no-install-recommends \
  && rm -rf ./*texlive* \
  && apt purge -qy equivs \
  && apt autoremove -qy --purge \
  && rm -rf /var/lib/apt/lists/* \
  && apt clean \
  && rm -rf /var/cache/apt/ \
  # Add to path and generate cache
  && $(find /opt/texlive -name tlmgr) path add \
  && (luaotfload-tool -u || true) \
  && (mtxrun --generate || true) \
  && (cp "$(find /opt/texlive -name texlive-fontconfig.conf)" /etc/fonts/conf.d/09-texlive-fonts.conf || true) \
  && fc-cache -fsv

WORKDIR /root
ENV \
  MANPATH=${MANPATH}:/opt/texlive/texmf-dist/doc/man \
  INFOPATH=${INFOPATH}:/opt/texlive/texmf-dist/doc/info
