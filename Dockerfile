FROM hashicorp/terraform:1.7.0

# Install additional tools (git, curl, etc.) if needed
RUN apk add --no-cache git curl bash aws-cli

WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
