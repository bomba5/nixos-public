# Module: modules/ai/open-webui.nix
# Purpose: Enable Ollama with CUDA acceleration and expose Open WebUI configured for localhost API.
# Options: No custom options.
# Usage: Import on hosts serving local LLMs via Ollama/Open WebUI; opens bind to all interfaces.
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  systemd.services.ollama.serviceConfig = {
    Environment = [ "OLLAMA_HOST=0.0.0.0:11434" ];
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
    environment = {
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_URL = "http://0.0.0.0:3000";
      ENABLE_MCP = "True";
      MCP_HOST   = "0.0.0.0";
      MCP_PORT   = "3001";
    };
  };
}
