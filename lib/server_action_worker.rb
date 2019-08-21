# frozen_string_literal: true

require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require_relative "./server_creator"


class ServerActionWorker
  include Sidekiq::Worker

  def perform(application_name)
    ServerCreator.new(application_name).call
  end
end
