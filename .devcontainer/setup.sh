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
echo ">>> Devcontainer setup complete."