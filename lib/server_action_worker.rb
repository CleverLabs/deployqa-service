# frozen_string_literal: true

require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require_relative "./server_creator"
require_relative "./server_deletor"


class ServerActionWorker
  include Sidekiq::Worker

  def perform(class_name, application_name)
    Object.const_get(class_name).new(application_name).call
  end
end
