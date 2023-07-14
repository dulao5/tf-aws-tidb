global:
  user: "ec2-user"
  group: "ec2-user"
  ssh_port: 22
  deploy_dir: "/tidb-deploy"
  data_dir: "/data"
  arch: "amd64"

monitored:
  node_exporter_port: 9100
  blackbox_exporter_port: 9115
  deploy_dir: "/tidb-deploy/monitored-9100"
  data_dir: "/data/monitored-9100"
  log_dir: "/tidb-deploy/monitored-9100/log"

# # Server configs are used to specify the runtime configuration of TiDB components.
# # All configuration items can be found in TiDB docs:
# # - TiDB: https://pingcap.com/docs/stable/reference/configuration/tidb-server/configuration-file/
# # - TiKV: https://pingcap.com/docs/stable/reference/configuration/tikv-server/configuration-file/
# # - PD: https://pingcap.com/docs/stable/reference/configuration/pd-server/configuration-file/
# # - TiFlash: https://docs.pingcap.com/tidb/stable/tiflash-configuration
# #
# # All configuration items use points to represent the hierarchy, e.g:
# #   readpool.storage.use-unified-pool
# #           ^       ^
# # - example: https://github.com/pingcap/tiup/blob/master/examples/topology.example.yaml.
# # You can overwrite this configuration via the instance-level `config` field.
server_configs:
  tidb:
    mem-quota-query: 2147483648 # 2GiB , tidbcloud : 8C16G/c5.2xlarge tidb configs
  tikv: # tidbcloud 8C32G/m5.2xlarge tikv configs
    server.grpc-concurrency: 3
    raftstore.apply-pool-size: 1
    raftstore.store-pool-size: 1
    rocksdb.defaultcf.max-write-buffer-number: 10
    rocksdb.writecf.max-write-buffer-number: 10
    rocksdb.lockcf.max-write-buffer-number: 10
    storage.io-rate-limit.max-bytes-per-sec: 301465600 # The baseline throughput of m5.2xlarge with EBS is 287.5MB/s.
    # storage.io-rate-limit.max-bytes-per-sec: 622592000 # The baseline throughput of m5.4xlarge with EBS is 593.75/s.
    backup.num-threads: 3
    backup.s3-multi-part-size: "30MB"
  # pd:
  tiflash:
    storage.io_rate_limit.max_bytes_per_sec: 301465600 # The baseline throughput of r5.2xlarge with EBS is 287.5MB/s.
    # storage.io_rate_limit.max_bytes_per_sec: 301465600 # The baseline throughput of r5.2xlarge with EBS is 287.5MB/s.
  # tiflash-learner:

# # Server configs are used to specify the configuration of PD Servers.
pd_servers:
  # # The ip address of the PD Server.
%{ for pd_private_id in pd_private_ips ~}
  - host: ${pd_private_id}
%{ endfor ~}

# # Server configs are used to specify the configuration of TiDB Servers.
tidb_servers:
%{ for tidb_private_id in tidb_private_ips ~}
  - host: ${tidb_private_id}
    # # SSH port of the server.
    # ssh_port: 22
    # # The port for clients to access the TiDB cluster.
    # port: 4000
    # # TiDB Server status API port.
    # status_port: 10080
    # # TiDB Server deployment file, startup script, configuration file storage directory.
    # deploy_dir: "/tidb-deploy/tidb-4000"
    # # TiDB Server log file storage directory.
    # log_dir: "/tidb-deploy/tidb-4000/log"
%{ endfor ~}

# # Server configs are used to specify the configuration of TiKV Servers.
tikv_servers:
%{ for tikv_private_ip in tikv_private_ips ~}
  # # The ip address of the TiKV Server.
  - host: ${tikv_private_ip}
    # # SSH port of the server.
    # ssh_port: 22
    # # TiKV Server communication port.
    # port: 20160
    # # TiKV Server status API port.
    # status_port: 20180
    # # TiKV Server deployment file, startup script, configuration file storage directory.
    # deploy_dir: "/tidb-deploy/tikv-20160"
    # # TiKV Server data storage directory.
    # data_dir: "/tidb-data/tikv-20160"
    # # TiKV Server log file storage directory.
    # log_dir: "/tidb-deploy/tikv-20160/log"
    # # The following configs are used to overwrite the `server_configs.tikv` values.
    # config:
    #   log.level: warn
%{ endfor ~}

# # Server configs are used to specify the configuration of TiFlash Servers.
tiflash_servers:
%{ for tiflash_private_ip in tiflash_private_ips ~}
  # # The ip address of the TiFlash Server.
  - host: ${tiflash_private_ip}
    # # SSH port of the server.
    # ssh_port: 22
    # # TiFlash TCP Service port.
    # tcp_port: 9000
    # # TiFlash HTTP Service port.
    # http_port: 8123
    # # TiFlash raft service and coprocessor service listening address.
    # flash_service_port: 3930
    # # TiFlash Proxy service port.
    # flash_proxy_port: 20170
    # # TiFlash Proxy metrics port.
    # flash_proxy_status_port: 20292
    # # TiFlash metrics port.
    # metrics_port: 8234
    # # TiFlash Server deployment file, startup script, configuration file storage directory.
    # deploy_dir: /tidb-deploy/tiflash-9000
    ## With cluster version >= v4.0.9 and you want to deploy a multi-disk TiFlash node, it is recommended to
    ## check config.storage.* for details. The data_dir will be ignored if you defined those configurations.
    ## Setting data_dir to a ','-joined string is still supported but deprecated.
    ## Check https://docs.pingcap.com/tidb/stable/tiflash-configuration#multi-disk-deployment for more details.
    # # TiFlash Server data storage directory.
    # data_dir: /tidb-data/tiflash-9000
    # # TiFlash Server log file storage directory.
    # log_dir: /tidb-deploy/tiflash-9000/log
%{ endfor ~}


# # Server configs are used to specify the configuration of Prometheus Server.  
monitoring_servers:
  # # The ip address of the Monitoring Server.
  - host: ${monitor_private_ip}
    # # SSH port of the server.
    # ssh_port: 22
    # # Prometheus Service communication port.
    # port: 9090
    # # ng-monitoring servive communication port
    # ng_port: 12020
    # # Prometheus deployment file, startup script, configuration file storage directory.
    # deploy_dir: "/tidb-deploy/prometheus-8249"
    # # Prometheus data storage directory.
    # data_dir: "/tidb-data/prometheus-8249"
    # # Prometheus log file storage directory.
    # log_dir: "/tidb-deploy/prometheus-8249/log"

# # Server configs are used to specify the configuration of Grafana Servers.  
grafana_servers:
  # # The ip address of the Grafana Server.
  - host: ${monitor_private_ip}
    # # Grafana web port (browser access)
    # port: 3000
    # # Grafana deployment file, startup script, configuration file storage directory.
    # deploy_dir: /tidb-deploy/grafana-3000

# # Server configs are used to specify the configuration of Alertmanager Servers.  
alertmanager_servers:
  # # The ip address of the Alertmanager Server.
  - host: ${monitor_private_ip}
    # # SSH port of the server.
    # ssh_port: 22
    # # Alertmanager web service port.
    # web_port: 9093
    # # Alertmanager communication port.
    # cluster_port: 9094
    # # Alertmanager deployment file, startup script, configuration file storage directory.
    # deploy_dir: "/tidb-deploy/alertmanager-9093"
    # # Alertmanager data storage directory.
    # data_dir: "/tidb-data/alertmanager-9093"
    # # Alertmanager log file storage directory.
    # log_dir: "/tidb-deploy/alertmanager-9093/log"

