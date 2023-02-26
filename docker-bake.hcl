// This is what is baked by GitHub Actions
group "default" { targets = ["bullseye-full"] }

variable "PUSH" {
  default = "false"
}

function "_output" {
  params = [push]
  result = push ? "type=registry" : "type=oci,dest=texlive.oci"
}

variable "AMD64" {
  default = "false"
}

variable "MULTIARCH" {
  default = "false"
}

function "_platforms" {
  params = [amd64, multi]
  result = multi ? "linux/amd64,linux/arm64" : ( amd64 ? "linux/amd64" : "linux/arm64" )
}

variable "VARIANT" {
  default = null
}

variable "SCHEME" {
  default = null
}

variable "DOCFILES" {
  default = null
}

variable "SRCFILES" {
  default = null
}

target "metadata-action-bullseye-full" {}

target "_args" {
  args = {
    "VARIANT" = VARIANT,
    "SCHEME" = SCHEME,
    "DOCFILES" = DOCFILES,
    "SRCFILES" = SRCFILES,
  }
}

target "_base" {
  inherits = ["_args"]

  args = {
    "BUILDKIT_SBOM_SCAN_CONTEXT" = "true",
  }
  attest = [
    "type=sbom",
    "type=provenance,mode=max",
  ]
  context = "."
  dockerfile = "Dockerfile"
  platforms = [_platforms(AMD64, MULTIARCH)]
  output = [_output(PUSH)]
}

target "bullseye-full" {
  inherits = [
    "metadata-action-bullseye-full",
    "_base",
  ]
}
