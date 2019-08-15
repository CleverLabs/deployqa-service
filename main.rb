require "docker"

application_name = ARGV[1]
port = rand(81_000..90_000)


KIND_CONFIG = %{
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: worker
  extraPortMappings:
  - containerPort: 31000
    hostPort: %{host_port}
    listenAddress: "127.0.0.1"
    protocol: tcp
}

kind_config_filename = "#{application_name}-kind-config.yaml"
File.open(kind_config_filename, "w") { |file| file.write(KIND_CONFIG % { host_port: port }) }

image = Docker::Image.build_from_dir(".")
image.tag("repo" => "some_repo_name", "tag" => application_name)

KUBERNETES_CONFIG = %{
apiVersion: v1
kind: Pod
metadata:
  name: %{application_name}
  labels:
    app: %{application_name}
spec:
  containers:
  - name: %{application_name}
    image: %{image_name}
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: %{application_name}
spec:
  type: NodePort
  selector:
    app: %{application_name}
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 31000
}

cluster_config_filename = "#{application_name}-cluster-config.yaml"
docker_image_name = "some_repo_name:#{application_name}"
File.open(cluster_config_filename, "w") { |file| file.write(KUBERNETES_CONFIG % { application_name: application_name, image_name: docker_image_name }) }

system("kind load docker-image #{docker_image_name}")
system("kind create cluster --config #{kind_config_filename} --name #{application_name}")
kind_connection_config = `kind get kubeconfig-path --name=#{application_name}`


# kube_config = Kubeclient::Config.read(kind_connection_config)

# kube_client = Kubeclient::Client.new(
#   kube_config.context.api_endpoint,
#   "v1",
#   ssl_options: kube_config.context.ssl_options,
#   auth_options: kube_config.context.auth_options
# )


`KUBECONFIG="#{kind_connection_config}" kubectl apply -f #{cluster_config_filename}`
