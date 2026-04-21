# Module: modules/logging/rsyslog.nix
# Purpose: Enable rsyslog and forward all logs to a remote syslog receiver.
# Options: No custom options.
# Usage: Import on hosts that should ship logs to a central rsyslog server.
#        Replace the destination IP/port below with your own collector.
{
  services.rsyslogd = {
    enable = true;

    # IMPORTANT: NixOS defaultConfig writes *.* to -/var/log/messages.
    # Override it so we don't fill /var with local logs.
    defaultConfig = "";

    extraConfig = ''
      # Prefer TCP for reliable forwarding:
      #   @  = UDP
      #   @@ = TCP
      *.* @@192.168.1.50:5516

      $ActionSendStreamDriverAuthMode    anon
      $ActionSendStreamDriverPermittedPeer *
      $ActionResumeRetryCount             -1
      $ActionQueueType                    LinkedList
      $ActionQueueSize                    10000
      $ActionQueueDiscardMark             9500
      $ActionQueueDiscardSeverity         4
    '';
  };
}
