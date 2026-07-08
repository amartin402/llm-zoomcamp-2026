set -euo pipefail

echo ">>> Starting devcontainer setup..."

# -------------------------------------------------------
# 1. SHELL PROMPT
# -------------------------------------------------------
grep -qxF 'export PS1="> "' ~/.bashrc \
  || echo 'export PS1="> "' >> ~/.bashrc

# -------------------------------------------------------
# 2. PYTHON — pip + uv
# -------------------------------------------------------
echo ">>> Setting up Python tooling..."

python3 -m pip install --upgrade pip --quiet
python3 -m pip install uv --quiet

echo ">>> uv version: $(uv --version)"

# -------------------------------------------------------
# 3. PYTHON DEPENDENCIES — isolated venv
# -------------------------------------------------------
VENV_PATH="/workspaces/llm-zoomcamp-2026/.venv"

if [ -f requirements.txt ]; then
  echo ">>> Creating uv virtual environment at $VENV_PATH..."
  uv venv "$VENV_PATH" --clear
  source "$VENV_PATH/bin/activate"
  uv pip install -r requirements.txt

  # Auto-activate venv in every new shell session
  grep -qxF "source $VENV_PATH/bin/activate" ~/.bashrc \
    || echo "source $VENV_PATH/bin/activate" >> ~/.bashrc

  echo ">>> Python venv ready at $VENV_PATH"
else
  echo ">>> No requirements.txt found — skipping Python dependency install."
fi

# -------------------------------------------------------
# 4. API KEYS — base64-encode for Kestra secrets
# -------------------------------------------------------
# Requires SECRET_GEMINI_API_KEY / SECRET_OPENAI_API_KEY / SECRET_TAVILY_API_KEY
# to be set as Codespaces secrets (Settings > Codespaces secrets on GitHub),
# holding the RAW (plaintext) key values. This script base64-encodes them and
# writes the encoded value to ~/.bashrc under the same SECRET_* name, since
# Kestra expects secrets as base64-encoded SECRET_-prefixed env vars.
echo ">>> Preparing Kestra secret env vars..."
 
encode_secret() {
  local secret_name="$1"
  local value="${!secret_name:-}"
 
  if [ -z "$value" ]; then
    echo ">>> Skipping $secret_name — not set (add it in Codespaces secrets if needed)."
    return
  fi
 
  local encoded
  encoded=$(echo -n "$value" | base64)
 
  # Remove any previous export of this var, then re-add (keeps it idempotent
  # and picks up updated key values on rebuild).
  sed -i "/^export ${secret_name}=/d" ~/.bashrc 2>/dev/null || true
  echo "export ${secret_name}=\"${encoded}\"" >> ~/.bashrc
  echo ">>> Wrote base64-encoded $secret_name to ~/.bashrc"
}
 
encode_secret SECRET_GEMINI_API_KEY   # required
encode_secret SECRET_OPENAI_API_KEY   # required for flow 3
encode_secret SECRET_TAVILY_API_KEY   # optional — flows 3, 5, 6

if [ -n "${SECRET_GEMINI_API_KEY:-}" ]; then
  sed -i '/^export GEMINI_API_KEY=/d' ~/.bashrc 2>/dev/null || true
  echo "export GEMINI_API_KEY=\"${SECRET_GEMINI_API_KEY}\"" >> ~/.bashrc
fi

# if [ -n "${SECRET_OPENAI_API_KEY:-}" ]; then
#   sed -i '/^export OPENAI_API_KEY=/d' ~/.bashrc 2>/dev/null || true
#   echo "export OPENAI_API_KEY=\"${SECRET_OPENAI_API_KEY}\"" >> ~/.bashrc
# fi

# -------------------------------------------------------
echo ">>> Devcontainer setup complete."
echo ">>> Run 'source ~/.bashrc' (or open a new terminal) before 'docker compose up -d' so the SECRET_* vars are loaded."