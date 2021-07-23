resource "null_resource" "cluster_configurator" {

  triggers = {
    kubeconfig = "${file(local_file.kubeconfig.filename)}"
  }

 provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "source install.sh"
 }
}