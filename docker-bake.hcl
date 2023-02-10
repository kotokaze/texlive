// This is what is baked by GitHub Actions
group "default" { targets = ["bullseye-full"] }

target "metadata-action-bullseye-full" {}

target "_common" {
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "pkg" {
  inherits = ["_common"]
  context = "."
  dockerfile = "Dockerfile"
  attest = [
    "type=sbom",
    "type=provenance,mode=max",
  ]
}

target "_bullseye" {
  args = {
    "DISTRO" = "bullseye",
  }
}

target "_full" {
  args = {
    "SCHEME" = "full",
    "DOCFILES" = "0",
    "SRCFILES" = "0",
  }
}

target "bullseye-full" {
  inherits = [
    "pkg",
    "metadata-action-bullseye-full",
    "_bullseye",
    "_full",
  ]
}
