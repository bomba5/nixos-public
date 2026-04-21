# Module: modules/ai/ollama.nix
# Purpose: Enable Ollama with CUDA acceleration, accessible on LAN.
# Usage: Import on hosts with an Nvidia GPU for local LLM inference.
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    host = "0.0.0.0";
    port = 11434;
  };
}
