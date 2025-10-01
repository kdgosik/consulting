

```
# Install uv package manager
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create virtual environment
uv venv && source .venv/bin/activate

# Install Flyte 2 (beta)
uv pip install --prerelease=allow flyte
```