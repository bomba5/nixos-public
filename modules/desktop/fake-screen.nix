# Module: modules/desktop/fake-screen.nix
# Purpose: Provide a fake display/EDID for headless systems needing a virtual monitor.
# Options: No custom options; adjust constants in the file for resolution/output.
# Usage: Import on hosts where a dummy HDMI output is required (e.g., streaming/remote desktop).
{ pkgs, ... }:

let
  resolution = "1920x1080";
  refreshRate = "60D";
  outputName = "HDMI-A-1";
  edidBase64 = ''
    AP///////wBMLZEPMU1YQwQfAQSlNR54Oy+tpFRHmSYPR0q/74CBwIEAgYCVAKnAswBxTwEBAjqAGHE4LUBYLEUAFDAhAAAeNT5YoIBlIEAwIDoAAAAAAAAaaUaIoJBlIEAwIDoAAAAAAAAaAAAA/QAY8A//PAAAAAAAAAAAAXkCAxXxSJA/QB8EEwMSIwkHB4MBAAAEdIAYcTgtQFgsRQAUMCEAAB4EdIDQcjgtQBAsRYAUMCEAAB5ah4CgcDhNQDAgNQAUMCEAABqHWnCggFQuYDAgNAAAAAAAABoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlQ==
  '';

  edidFileName = "edid-${resolution}.bin";
  kernelParam = "video=${outputName}:${resolution}@${refreshRate}";
  edidPackage = pkgs.runCommand "edid-${resolution}" { } ''
        mkdir -p "$out/lib/firmware/edid"
        base64 -d > "$out/lib/firmware/edid/${edidFileName}" <<'EOF'
    ${edidBase64}
    EOF
  '';
in
{
  hardware.display = {
    edid.enable = true;
    edid.packages = [ edidPackage ];
    outputs.${outputName}.edid = edidFileName;
  };

  boot.kernelParams = [ kernelParam ];
}
