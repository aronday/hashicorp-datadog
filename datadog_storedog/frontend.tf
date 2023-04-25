resource "kubernetes_deployment" "frontend" {
  depends_on = [
    kubernetes_namespace.storedog
  ]
  metadata {
    labels = {
      "app"                    = "ecommerce"
      "service"                = "store-frontend"
      "tags.datadoghq.com/env" = "development"
    }
    name      = "store-frontend"
    namespace = kubernetes_namespace.storedog.id
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "ecommerce"
        service = "store-frontend"
      }
    }
    strategy {
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          "app"                    = "ecommerce"
          "service"                = "store-frontend"
          "tags.datadoghq.com/env" = "development"
        }
      }

      spec {
        container {
          args    = ["docker-entrypoint.sh"]
          command = ["sh"]
          env {
            name  = "DB_USERNAME"
            value = "user"
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = "db-password"
                key  = "pw"
              }
            }
          }
          env {
            name = "DD_AGENT_HOST"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name = "DD_SERVICE"
            value_from {
              field_ref {
                field_path = "metadata.labels['tags.datadoghq.com/service']"
              }
            }
          }
          
          env {
            name  = "DD_LOGS_INJECTION"
            value = true
          }

          env {
            name = "DD_ENV"
            value_from {
              field_ref {
                field_path = "metadata.labels['tags.datadoghq.com/env']"
              }
            }
          }

          env {
            name  = "DD_ANALYTICS_ENABLED"
            value = true
          }

          env {
            name  = "DISCOUNTS_ROUTE"
            value = "http://discounts"
          }

          env {
            name  = "DISCOUNTS_PORT"
            value = "5001"
          }

          env {
            name  = "ADS_ROUTE"
            value = "http://advertisements"
          }

          env {
            name  = "ADS_PORT"
            value = "5002"
          }

          env {
            name  = "DD_CLIENT_TOKEN"
            value = var.DD_CLIENT_TOKEN
          }

          env {
            name  = "DD_APPLICATION_ID"
            value = var.DD_APPLICATION_ID
          }


          image             = "public.ecr.aws/x2b9z2t7/ddtraining/storefront-fixed:2.2.1"
          image_pull_policy = "Always"
          name              = "ecommerce-spree-observability"
          port {
            container_port = 3000
            protocol       = "TCP"
          }

          resources {
            # "limits" = {}
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  depends_on = [
    kubernetes_namespace.storedog
  ]
  metadata {
    name      = "store-frontend"
    namespace = kubernetes_namespace.storedog.id
    labels = {
      app     = "ecommerce"
      service = "store-frontend"
    }
  }
  spec {
    selector = {
      app = "ecommerce"
      service = "store-frontend"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}

output "frontend" {
  value = "http://${kubernetes_service.frontend.status.0.load_balancer.0.ingress.0.hostname}"
}