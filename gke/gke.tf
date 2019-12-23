resource "google_container_cluster" "advent_gke" {
  name     = "${var.service_name}-${var.env}-gke"
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 2

  master_auth {
    username = var.user_name
    password = var.user_passwd

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "advent_k8s_node" {
  name       = "${var.service_name}-${var.env}-k8s-node"
  location   = var.location
  cluster    = google_container_cluster.advent_gke.name
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = var.machine

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
