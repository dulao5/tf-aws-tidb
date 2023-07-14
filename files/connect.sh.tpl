#!/bin/sh

## create private key
# 
terraform output -json | jq -r .tidb_bastion_keypair_private_key.value > ~/.ssh/tidb-test-bastion
chmod 600 ~/.ssh/tidb-test-bastion

ssh -i ~/.ssh/tidb-test-bastion ec2-user@${bastion_public_ip}

## tidb setup commands
#
# tiup cluster check tiup-topology.yaml
# tiup cluster check tiup-topology.yaml --apply

## cluster deploy
# 
# tiup cluster deploy <cluster-name> <version> tiup-topology.yaml
# tiup cluster start <cluster-name> --init

## connect tidb
# terraform output # output nlb_internal_tidb
# mysql --user root --port 4000 --host ${nlb_internal_tidb} -p 
