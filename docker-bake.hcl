// This is what is baked by GitHub Actions
group "default" { targets = ["bullseye-full"] }

variable "PUSH" {
  default = "false"
}

function "_output" {
  params = [push]
  result = push ? "type=registry" : "type=oci,dest=texlive.oci"
}

target "metadata-action-bullseye-full" {}

target "_platforms" {
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "_base" {
  args = {
    "BUILDKIT_SBOM_SCAN_CONTEXT" = "true",
    "VARIANT" = "bullseye",
    "SCHEME" = "full",
    "DOCFILES" = "0",
    "SRCFILES" = "0",
  }
  attest = [
    "type=sbom",
    "type=provenance,mode=max",
  ]
  context = "."
  dockerfile = "Dockerfile"
  output = [_output(PUSH)]
}

target "bullseye-full" {
  inherits = [
    "metadata-action-bullseye-full",
    "_base",
  ]
}
