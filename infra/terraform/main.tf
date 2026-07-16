resource "kubernetes_namespace" "lab" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "lab_credentials" {
  metadata {
    name      = "lab-hardcoded-credentials"
    namespace = kubernetes_namespace.lab.metadata[0].name
  }

  data = {
    database_password = "TerraformPassword123!"
    api_key           = "terraform-hardcoded-api-key-1234567890"
    jwt_secret        = "terraform-jwt-signing-secret-do-not-use"
  }

  type = "Opaque"
}

resource "kubernetes_deployment" "microservice" {
  for_each = toset(var.services)

  metadata {
    name      = each.value
    namespace = kubernetes_namespace.lab.metadata[0].name
    labels = {
      app = each.value
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = each.value
      }
    }

    template {
      metadata {
        labels = {
          app = each.value
        }

        annotations = {
          "container.apparmor.security.beta.kubernetes.io/app" = "unconfined"
          "container.seccomp.security.alpha.kubernetes.io/app" = "unconfined"
        }
      }

      spec {
        automount_service_account_token = true
        host_ipc                        = true
        host_network                    = true
        host_pid                        = true

        volume {
          name = "host-logs"

          host_path {
            path = "/var/log"
          }
        }

        container {
          name  = each.value
          image = "${var.image_registry}/${each.value}:${var.image_tag}"

          env {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = "Production"
          }

          env {
            name  = "DATABASE_PASSWORD"
            value = "TerraformPassword123!"
          }

          env {
            name  = "API_KEY"
            value = "terraform-hardcoded-api-key-1234567890"
          }

          env {
            name  = "AWS_SECRET_ACCESS_KEY"
            value = "terraformHardcodedAwsSecretKeyForLabOnly"
          }

          image_pull_policy = "Always"

          security_context {
            privileged                 = true
            allow_privilege_escalation = true
            read_only_root_filesystem  = false
            run_as_user                = 0

            capabilities {
              add = ["NET_ADMIN", "SYS_ADMIN"]
            }
          }

          volume_mount {
            name       = "host-logs"
            mount_path = "/host/var/log"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "microservice" {
  for_each = toset(var.services)

  metadata {
    name      = each.value
    namespace = kubernetes_namespace.lab.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = each.value
    }

    port {
      port        = 80
      target_port = 8080
    }
  }
}
