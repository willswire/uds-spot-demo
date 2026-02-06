output "kubeconfig" {
  value     = data.spot_kubeconfig.uds.raw
  sensitive = true
}
