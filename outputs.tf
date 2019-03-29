output "neptune_cluster_instances" {
  value = "${aws_neptune_cluster.example.cluster_members}"
}

output "neptune_cluster_endpoint" {
  value = "${aws_neptune_cluster.example.endpoint}"
}

output "SSH Port Forward Command" {
  value = "ssh -L8182:${aws_neptune_cluster.example.endpoint}:8182 ec2-user@${aws_instance.neptune-ec2-connector.public_ip}"
}