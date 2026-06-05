FROM nousresearch/hermes-agent:latest

LABEL org.opencontainers.image.title="create-hermes-workspace" \
      org.opencontainers.image.description="Opinionated Hermes Agent workspace scaffold" \
      org.opencontainers.image.source="https://github.com/eddremonts86/create-hermes-workspace" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.authors="Eduardo Inerarte <eddremonts86@gmail.com>"

# The base image already includes the Hermes Agent runtime, the Python
# virtualenv, and the gateway. This Dockerfile is intentionally minimal —
# most of the "workspace" lives in the mounted volume at /opt/data so that
# colleagues can `git pull` updates without rebuilding the image.
#
# Use this Dockerfile when you want to:
#   1. Pin the base image version (replace `:latest` with `:vX.Y.Z`).
#   2. Bake additional system packages or skills into the image.
#   3. Distribute a pre-configured workspace to teammates via a registry.
#
# For local development the docker-compose.yml mounts ./:/opt/data and
# the image is rebuilt only when this Dockerfile changes.

# (Optional) Install extra system packages:
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     graphviz imagemagick && rm -rf /var/lib/apt/lists/*

# (Optional) Bake in extra skills that should be available to all teammates:
# COPY ./skills /opt/hermes/skills
