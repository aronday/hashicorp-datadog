resource "kubernetes_deployment" "discounts" {
  depends_on = [
    kubernetes_namespace.storedog
  ]
metadata {
    labels = {
      "app"                    = "ecommerce"
      "service"                = "discounts"
      "tags.datadoghq.com/env" = "development"
    }
    name      = "discounts"
    namespace = kubernetes_namespace.storedog.id
    annotations = {
      "ad.datadoghq.com/discounts.logs" = " [{'source': 'python', 'service': 'discounts-service'}]"
    }
  }
spec {
  replicas = 1

    selector {
      match_labels = {
        app     = "ecommerce"
        service = "discounts"
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
          "service"                = "discounts"
          "tags.datadoghq.com/env" = "development"
        }
      }

      spec {
        container {
          args    = ["flask", "run", "--port=5001", "--host=0.0.0.0"]
          command = ["ddtrace-run"]
          env {
            name  = "FLASK_APP"
            value = "discounts.py"
          }
          env {
            name  = "FLASK_DEBUG"
            value = "1"
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "db-password"
                key  = "pw"
              }
            }
          }
          
          env {
            name  = "POSTGRES_USER"
            value = "user"
          }
          
          env {
            name  = "POSTGRES_HOST"
            value = "db"
          }
          
          env {
            name  = "DATADOG_SERVICE_NAME"
            value = "discounts-service"
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
            name  = "DD_PROFILING_ENABLED"
            value = true
          }

          image             = "ddtraining/discounts:latest"
          image_pull_policy = "Always"
          name              = "discounts"
          port {
            container_port = 5001
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "discounts" {
  depends_on = [
    kubernetes_namespace.storedog
  ]
  metadata {
    name      = "discounts"
    namespace = kubernetes_namespace.storedog.id
    labels = {
      app     = "ecommerce"
      service = "discounts"
    }
  }
  spec {
    selector = {
      app = "ecommerce"
      service = "discounts"
    }
    port {
      port        = 5001
      target_port = 5001
    }
      session_affinity = "None"
      type = "ClusterIP"
  }
}