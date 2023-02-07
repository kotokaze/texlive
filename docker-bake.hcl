// This is what is baked by GitHub Actions
group "default" { targets = ["bullseye-full"] }

target "docker-metadata-action" {}

target "build" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "bullseye-full" {
  inherits = ["build", "docker-metadata-action"]
  args = {
    "VARIANT" = "bullseye",
    "SCHEME" = "full",
    "DOCFILES" = "0",
    "SRCFILES" = "0",
  }
}
