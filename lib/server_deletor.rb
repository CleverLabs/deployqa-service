# frozen_string_literal: true

class ServerDeletor
  def initialize(application_name)
    @application_name = application_name
  end

  def call
    system("kind delete cluster --name #{@application_name}")
  end
end
