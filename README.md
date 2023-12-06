# TeX Live Image
[![Docker](https://github.com/kotokaze/texlive/actions/workflows/publish.yml/badge.svg?event=schedule)](https://github.com/kotokaze/texlive/actions/workflows/publish.yml)  

Daily build docker image of Tex Live, supports `linux/amd64` and `linux/arm64`  

## Usage

Pull from [Docker Hub Registry](https://hub.docker.com/r/kotokaze/texlive):

```bash
docker pull kotokaze/texlive:latest
```

Pull from GitHub Container Registry:

```bash
docker pull ghcr.io/kotokaze/texlive:latest
```

## Available tags
### TeX Live full

| Tag | Description |
| --- | --- |
| `latest` | Latest tag version |
| `TL2023-bullseye-full-vX.Y[.Z]` | Tag on this repo |
| `TL2023-bullseye-full-nightly` | Daily build |
| `TL2023-bullseye-full-<Commit Hash>` | Commit hash on branch master |
