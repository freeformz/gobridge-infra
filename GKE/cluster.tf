provider "google" {
  credentials = "${file("../creds/GoBridge-23295db7a29c.json")}"
  project     = "gobridge"
  region      = "us-central1"
  zone        = "us-central1-c"
}

data "google_container_engine_versions" "uscentral1" {
  location       = "us-central1"
  version_prefix = "1.13."
}

resource "google_container_cluster" "primary" {
  name     = "primary"
  location = "us-central1"

  node_version = "${data.google_container_engine_versions.uscentral1.latest_node_version}"
  min_master_version = "${data.google_container_engine_versions.uscentral1.latest_master_version}"
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "primary"
  location   = "us-central1"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}