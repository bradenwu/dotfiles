# Load environment variables from .env file if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Clear proxy settings
unset http_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset https_proxy

# Set GLM base URL (can be overridden by .env)
# Note: ANTHROPIC_AUTH_TOKEN and model settings should be configured in .env file
export ANTHROPIC_BASE_URL="http://open.bigmodel.cn/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="${GLM_TOKEN}"
export ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.6"
export ANTHROPIC_DEFAULT_SONNET_MODEL="GLM-4.6"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="GLM-4.5-Air"
