# frozen_string_literal: true

require "docker"

class DockerImageWrapper
  def initialize(application_name, repo_full_name)
    @application_name = application_name
    @image_name = repo_full_name.split("/").join("_")
    @repo_path = "/root/instances/#{application_name}/#{repo_full_name.split("/").last}"
  end

  def build
    image = Docker::Image.build_from_dir(@repo_path) do |v|
      log = JSON.parse(v)
      $stdout.puts log["stream"] if log && log.has_key?("stream")
    end

    image.tag("repo" => @image_name, "tag" => @application_name)
    "#{@image_name}:#{@application_name}"
  end
end
