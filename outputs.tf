output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "zones" {
  value       = var.zones
  description = "Node Zones"
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}