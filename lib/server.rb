# frozen_string_literal: true

require "sinatra"
require_relative "./server_action_worker"
require_relative "./addons/factory"

set :environment, :production
set :bind, "0.0.0.0"
set :port, 8100

get "/application/:application_name/status" do
  "Hello world!"
end

post "/application/:application_name" do
  ServerActionWorker.perform_async(ServerCreator, params[:application_name])
  "Ok"
end

delete "/application/:application_name" do
  ServerActionWorker.perform_async(ServerDeletor, params[:application_name])
  "Ok"
end

post "/addons/:addon_name" do
  
end
