# frozen_string_literal: true

require "sinatra"
require "sinatra/json"
require_relative "./server_action_worker"
require_relative "./addons/factory"
require_relative "./git_wrapper"
require_relative "./docker_image_wrapper"

set :environment, :production
set :bind, "0.0.0.0"
set :port, 8100
set :server_settings, RequestTimeout: 120

get "/application/:application_name/status" do
  "Hello world!"
end

post "/application/:application_name" do
  ServerActionWorker.perform_async(ServerCreator, params[:application_name])
  json status: "Ok"
end

delete "/application/:application_name" do
  ServerActionWorker.perform_async(ServerDeletor, params[:application_name])
  json status: "Ok"
end

post "/addons/:addon_name" do
  
end

post "/builds/:application_name/clone_code" do
  GitWrapper.clone_by_uri(params[:application_name], params[:repo_path], params[:repo_uri])
  json status: "Ok"
end

post "/builds/:application_name/build" do
  DockerImageWrapper.new(params[:application_name], params[:repo_path]).build
  json status: "Ok"
end

post "/builds/:application_name/load_to_cluster" do
  docker_image_name = "#{params[:repo_path].split("/").join("_")}:#{params[:application_name]}"
  system("kind load docker-image #{docker_image_name} --name abc")
  json status: "Ok"
end
