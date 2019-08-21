# frozen_string_literal: true

require "docker"
require_relative "./port"

class ServerCreator
  REPO_PATH = "/home/ubuntu/deployqa"
  CONFIGURATIONS_PATH = "/home/ubuntu/service_configs"
  IMAGE_REPO_NAME = "deployqa_internal_project_instance"
  KIND_CONFIG = %{
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: worker
  extraPortMappings:
  - containerPort: 31000
    hostPort: %{host_port}
    listenAddress: "0.0.0.0"
    protocol: tcp
}
  KUBERNETES_CONFIG = %{
apiVersion: v1
kind: Pod
metadata:
  name: "%{application_name}"
  labels:
    app: "%{application_name}"
spec:
  containers:
  - name: %{application_name}
    image: %{image_name}
    args: ["bundle", "exec", "rails", "s", "-p", "80", "-b", "0.0.0.0"]
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: "%{application_name}"
spec:
  type: NodePort
  selector:
    app: "%{application_name}"
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 31000
}

  def initialize(application_name)
    @application_name = application_name
    @port = Port.allocate
  end

  def call
    kind_config_filename = create_kind_config
    docker_image_name = build_docker_image
    cluster_config_filename = craete_cluster_config(docker_image_name)
    setup_cluster(kind_config_filename, docker_image_name)

    apply_kubectl_config(cluster_config_filename)
  end

  def create_kind_config
    puts " -- creating kind_config"
    kind_config_filename = "#{CONFIGURATIONS_PATH}/deployqa-internal-#{@application_name}-kind-config.yaml"
    File.open(kind_config_filename, "w") { |file| file.write(KIND_CONFIG % { host_port: @port }) }
    kind_config_filename
  end

  def build_docker_image
    puts " -- building docker"
    image = Docker::Image.build_from_dir(REPO_PATH)
    image.tag("repo" => IMAGE_REPO_NAME, "tag" => @application_name)
    "#{IMAGE_REPO_NAME}:#{@application_name}"
  end

  def craete_cluster_config(docker_image_name)
    puts " -- creating cluster_config"
    cluster_config_filename = "#{CONFIGURATIONS_PATH}/deployqa-internal-#{@application_name}-cluster-config.yaml"
    File.open(cluster_config_filename, "w") { |file| file.write(KUBERNETES_CONFIG % { application_name: @application_name, image_name: docker_image_name }) }
    cluster_config_filename
  end

  def setup_cluster(kind_config_filename, docker_image_name)
    puts " -- creating cluster"
    system("kind create cluster --config #{kind_config_filename} --name #{@application_name}")

    puts " -- loading docker to kind"
    system("kind load docker-image #{docker_image_name} --name #{@application_name}")
  end

  def apply_kubectl_config(cluster_config_filename)
    puts " -- applying kube config"
    kind_connection_config = `kind get kubeconfig-path --name=#{@application_name}`
    system({ "KUBECONFIG" => kind_connection_config.strip }, "kubectl apply -f #{cluster_config_filename}")
  end
end
