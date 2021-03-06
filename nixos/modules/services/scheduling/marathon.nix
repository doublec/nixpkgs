{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.marathon;

in {

  ###### interface

  options.services.marathon = {
    enable = mkOption {
      type = types.uniq types.bool;
      default = false;
      description = ''
	Whether to enable the marathon mesos framework.
      '';
    };

    httpPort = mkOption {
      type = types.int;
      default = 8080;
      description = ''
	Marathon listening port for HTTP connections.
      '';
    };

    master = mkOption {
      type = types.str;
      default = "zk://${concatStringsSep "," cfg.zookeeperHosts}/mesos";
      example = "zk://1.2.3.4:2181,2.3.4.5:2181,3.4.5.6:2181/mesos";
      description = ''
	Mesos master address. See <link xlink:href="https://mesosphere.github.io/marathon/docs/"/> for details.
      '';
    };

    zookeeperHosts = mkOption {
      type = types.listOf types.str;
      default = [ "localhost:2181" ];
      example = [ "1.2.3.4:2181" "2.3.4.5:2181" "3.4.5.6:2181" ];
      description = ''
	ZooKeeper hosts' addresses.
      '';
    };

    extraCmdLineOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--https_port=8443" "--zk_timeout=10000" "--marathon_store_timeout=2000" ];
      description = ''
	Extra command line options to pass to Marathon.
	See <link xlink:href="https://mesosphere.github.io/marathon/docs/command-line-flags.html"/> for all possible flags.
      '';
    };

    environment = mkOption {
      default = { };
      type = types.attrs;
      example = { JAVA_OPTS = "-Xmx512m"; MESOSPHERE_HTTP_CREDENTIALS = "username:password"; };
      description = ''
	Environment variables passed to Marathon.
      '';
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.marathon = {
      description = "Marathon Service";
      environment = cfg.environment;
      wantedBy = [ "multi-user.target" ];
      after = [ "network-interfaces.target" "zookeeper.service" "mesos-master.service" "mesos-slave.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.marathon}/bin/marathon --master ${cfg.master} --zk zk://${concatStringsSep "," cfg.zookeeperHosts}/marathon --http_port ${toString cfg.httpPort} ${concatStringsSep " " cfg.extraCmdLineOptions}";
        User = "marathon";
        Restart = "always";
        RestartSec = "2";
      };
    };

    users.extraUsers.marathon = {
      description = "Marathon mesos framework user";
    };
  };
}
