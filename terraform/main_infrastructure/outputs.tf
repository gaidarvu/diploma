output "worker_vm_details" {
  value = [
    for instance in yandex_compute_instance.worker_instances : {
      name        = instance.name,
      ext_ip_address  = instance.network_interface[0].nat_ip_address
      int_ip_address  = instance.network_interface[0].ip_address
    }
  ]
}

output "master_vm_details" {
  value = [
    for instance in yandex_compute_instance.master_instances : {
      name        = instance.name,
      ext_ip_address  = instance.network_interface[0].nat_ip_address
      int_ip_address  = instance.network_interface[0].ip_address
    }
  ]
}

output "nat_vm_details" {
  value = [
    for instance in yandex_compute_instance.nat_instances : {
      name        = instance.name,
      ext_ip_address  = instance.network_interface[0].nat_ip_address
      int_ip_address  = instance.network_interface[0].ip_address
    }
  ]
}