output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "tidb" {
  value = "${join("\n", module.ec2_internal_tidb.*.private_ip)}"
}

output "tikv" {
  value = "${join("\n", module.ec2_internal_tikv.*.private_ip)}"
}

output "pd" {
  value = "${join("\n", module.ec2_internal_pd.*.private_ip)}"
}

output "monitor" {
  value = "${join("\n", module.ec2_internal_monitor.*.private_ip)}"
}

output "monitor-url" {
  value = "${join("\n", module.ec2_internal_monitor.*.private_dns)}"  
}

output "ticdc" {
  value = "${join("\n", module.ec2_internal_ticdc.*.private_ip)}"
}

output "bastion_ip" {
  value = "${join("\n", module.ec2_bastion.*.public_ip)}"
}

output "grafana_url" {
  value = "${module.api_gateway_grafana.apigatewayv2_api_api_endpoint}"
}

output "tidash_url" {
  value = "${module.api_gateway_tidash.apigatewayv2_api_api_endpoint}/dashboard/"
}

# tidb_bastion keypair private key
output "tidb_bastion_keypair_private_key" {
  value = "${module.key_pair_tidb_bastion.private_key_openssh}"
  sensitive = true
}

output "nlb-endpoint" {
  value = "${module.nlb_internal_tidb.lb_dns_name}"
}