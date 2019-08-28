# frozen_string_literal: true

require "ice_nine"

class Configurations
  KIND_CONFIG = IceNine.deep_freeze({
    "apiVersion" => "kind.sigs.k8s.io/v1alpha3",
    "kind" => "Cluster",
    "nodes" => [
      {
        "role" => "control-plane"
      },
      {
        "role" => "worker",
        "extraPortMappings" => [
          {
            "containerPort" => 31000,
            "hostPort" => nil,
            "listenAddress" => "0.0.0.0",
            "protocol" => "tcp"
          }
        ]
      }
    ]
  })

  WEB_DEPLOYMENT_CONFIG = IceNine.deep_freeze({
    "apiVersion" => "v1",
    "kind" => "Pod",
    "metadata" => {
      "name" => nil,
      "labels" => { "app" => nil }
    },
    "spec" => {
      "containers" => [
        {
          "name" => nil,
          "image" => nil,
          "env" => nil,
          "args" => nil,
          "ports" => [{ "containerPort" => 80 }]
        }
      ]
    }
  })

  WEB_SERVICE_CONFIG = IceNine.deep_freeze({
    "apiVersion" => "v1",
    "kind" => "Service",
    "metadata" => {
      "name" => nil
    },
    "spec" => {
      "type" => "NodePort",
      "selector" => { "app" => nil },
      "ports" => [{ "protocol" => "TCP", "port" => 80, "targetPort" => 80, "nodePort" => 31000 }]
    }
  })


  DB_DEPLOYMENT_CONFIG = IceNine.deep_freeze({
    "apiVersion" => "apps/v1",
    "kind" => "Deployment",
    "metadata" => {
      "name" => "postgres",
      "labels" => { "app" => nil }
    },
    "spec" => {
      "replicas" => 1,
      "selector" => {
        "matchLabels" => {
          "app" => nil,
          "tier" => "database"
        }
      },
      "template" => {
        "metadata" => {
          "name" => "postgres",
          "labels" => {
            "app" => nil,
            "tier" => "database"
          }
        },
        "spec" => {
          "containers" => [{
            "name" => "postgres",
            "image" => "postgres:9.6-alpine",
            "env" => [
              { "name" => "POSTGRES_USER", "value" => "user" },
              { "name" => "POSTGRES_PASSWORD", "value" => "password" },
              { "name" => "POSTGRES_DB", "value" => "deployqa" },
              { "name" => "PGDATA", "value" => "/var/lib/postgresql/data" }
            ],
            "ports" => [{ "containerPort" => 5432 }]
          }]
        }
      }
    }
  })

  DB_SERVICE_CONFIG = IceNine.deep_freeze({
    "apiVersion" => "v1",
    "kind" => "Service",
    "metadata" => {
      "name" => "postgres",
      "labels" => { "app" => nil }
    },
    "spec" => {
      "ports" => [{ "port" => 5432 }],
      "selector" => {
        "app" => nil,
        "tier" => "database"
      }
    }
  })


  def kind_config(port:)
    config = Marshal.load(Marshal.dump(KIND_CONFIG))
    config.fetch("nodes")[1].fetch("extraPortMappings")[0]["hostPort"] = port.to_i
    config.to_yaml
  end

  def web_deployment_config(application_name:, image:)
    config = Marshal.load(Marshal.dump(WEB_DEPLOYMENT_CONFIG))
    config.fetch("metadata")["name"] = application_name
    config.fetch("metadata").fetch("labels")["app"] = application_name
    config.fetch("spec").fetch("containers")[0]["name"] = application_name
    config.fetch("spec").fetch("containers")[0]["image"] = image
    config.fetch("spec").fetch("containers")[0]["args"] = "bundle exec rails s -p 80 -b 0.0.0.0".split
    config.fetch("spec").fetch("containers")[0]["env"] = [
      { "name" => "RAILS_ENV", "value" => "production" },
      { "name" => "SECRET_KEY_BASE", "value" => "d01cc0d6-f96c-4c34-9411-f28e54a01ee5" },
      { "name" => "RAILS_LOG_TO_STDOUT", "value" => "true" },
      { "name" => "DB_HOST", "value" => "postgres" },
      { "name" => "DB_NAME", "value" => "deployqa" },
      { "name" => "DB_USERNAME", "value" => "user" },
      { "name" => "DB_PASSWORD", "value" => "password" }
    ]
    config.to_yaml
  end

  def web_service_config(application_name:)
    config = Marshal.load(Marshal.dump(WEB_SERVICE_CONFIG))
    config.fetch("metadata")["name"] = application_name
    config.fetch("spec").fetch("selector")["app"] = application_name
    config.to_yaml
  end

  def db_deployment_config(application_name:)
    config = Marshal.load(Marshal.dump(DB_DEPLOYMENT_CONFIG))
    config.fetch("metadata").fetch("labels")["app"] = application_name
    config.fetch("spec").fetch("selector").fetch("matchLabels")["app"] = application_name
    config.fetch("spec").fetch("template").fetch("metadata").fetch("labels")["app"] = application_name
    config.to_yaml
  end

  def db_service_config(application_name:)
    config = Marshal.load(Marshal.dump(DB_SERVICE_CONFIG))
    config.fetch("metadata").fetch("labels")["app"] = application_name
    config.fetch("spec").fetch("selector")["app"] = application_name
    config.to_yaml
  end
end
