# Intentionally vulnerable Terraform for Veracode IaC lab tests.
# Do not apply this configuration in any real environment.

resource "kubernetes_service_account" "overprivileged" {
  metadata {
    name      = "veracode-lab-overprivileged"
    namespace = var.namespace
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "cluster_admin" {
  metadata {
    name = "veracode-lab-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.overprivileged.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_pod" "insecure_debug_pod" {
  metadata {
    name      = "veracode-lab-insecure-debug"
    namespace = var.namespace
    labels = {
      app = "veracode-lab-insecure-debug"
    }
  }

  spec {
    automount_service_account_token = true
    host_network                    = true
    host_pid                        = true

    volume {
      name = "docker-socket"

      host_path {
        path = "/var/run/docker.sock"
      }
    }

    volume {
      name = "host-root"

      host_path {
        path = "/"
      }
    }

    container {
      name              = "debug"
      image             = "ubuntu:latest"
      image_pull_policy = "Always"
      command           = ["/bin/sh", "-c", "sleep 3600"]

      env {
        name  = "DATABASE_URL"
        value = "Server=tcp:public-db.example.com,1433;User ID=sa;Password=TerraformLabPassword123!;Encrypt=False"
      }

      env {
        name  = "JWT_SIGNING_KEY"
        value = "terraform-lab-hardcoded-jwt-signing-key"
      }

      security_context {
        privileged                 = true
        allow_privilege_escalation = true
        read_only_root_filesystem  = false
        run_as_user                = 0

        capabilities {
          add = ["SYS_ADMIN", "NET_ADMIN", "DAC_READ_SEARCH"]
        }
      }

      volume_mount {
        name       = "docker-socket"
        mount_path = "/var/run/docker.sock"
      }

      volume_mount {
        name       = "host-root"
        mount_path = "/host"
      }
    }
  }
}
