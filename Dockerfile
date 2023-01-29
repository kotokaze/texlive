### base stage
FROM mcr.microsoft.com/vscode/devcontainers/base:bullseye as base

ENV \
  DEBIAN_FRONTEND=noninteractive \
  TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1

# Install dependencies
RUN apt update && apt install -y --no-install-recommends \
  fontconfig default-jre libgetopt-long-descriptive-perl \
  libunicode-linebreak-perl libfile-homedir-perl libyaml-tiny-perl \
  ghostscript \
  libsm6 \
  python3-pygments python-is-python3 \
  gnuplot-nox \
  && rm -rf /var/lib/apt/lists/*


### builder stage
FROM base as builder
WORKDIR /tmp

# Create profile
ARG TEXLIVE_SCHEME=full
ARG AUTOBACKUP=0
ARG DOCFILES=0
ARG SRCFILES=0
COPY texlive.installation.profile .
RUN sed -i \
  -re "s|(selected_scheme\ scheme-)full|\1"${TEXLIVE_SCHEME}"|" \
  -re "s|(tlpdbopt_autobackup\ )0|\1"${AUTOBACKUP}"|" \
  -re "s|(tlpdbopt_install_docfiles\ )0|\1"${AUTOBACKUP}"|" \
  -re "s|(tlpdbopt_install_srcfiles\ )0|\1"${AUTOBACKUP}"|" \
  texlive.installation.profile \
  && cat texlive.installation.profile

# Download and install the installer
ARG TEXLIVE_REPO=https://mirror.ctan.org/systems/texlive/tlnet
RUN curl -sSLO https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
  && zcat install-tl-unx.tar.gz | tar -xvf - \
  && cd install-tl-2* \
  && perl ./install-tl -profile ../texlive.installation.profile --no-interaction  --repository=${TEXLIVE_REPO} \
  && cd .. \
  && rm -rf ./install-tl-2*


### final stage
FROM base
WORKDIR /tmp

# Install
COPY --from=builder /opt/texlive /opt/texlive

# download and install equivs file for dummy package
RUN apt update && apt install -y --no-install-recommends equivs \
  && curl https://tug.org/texlive/files/debian-equivs-2022-ex.txt -o texlive-local \
  && sed -i -e "s/2022/9999/" -e "/Depends: freeglut3/d" texlive-local \
  && equivs-build texlive-local \
  && dpkg -i texlive-local_9999.99999999-1_all.deb \
  && apt install -y --no-install-recommends \
  && rm -rf ./*texlive* \
  && apt remove -y --purge equivs \
  && apt autoremove -y --purge \
  && rm -rf /var/lib/apt/lists/* \
  && apt clean \
  && rm -rf /var/cache/apt/

# Add to path and install packages
RUN $(find /opt/texlive -name tlmgr) path add \
  && tlmgr install \
  latexmk

ENTRYPOINT [ "/bin/bash" ]
