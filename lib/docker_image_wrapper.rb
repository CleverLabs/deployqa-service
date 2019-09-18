# frozen_string_literal: true

class DockerImageWrapper
  def initialize(application_name, repo_full_name)
    @application_name = application_name
    @image_name = repo_full_name.split("/").join("_")
    @repo_path = "/home/ubuntu/cloned_repos/#{application_name}/#{repo_full_name.split("/").last}"
  end

  def build
    image = Docker::Image.build_from_dir(@repo_path)
    image.tag("repo" => @image_name, "tag" => @application_name)
    "#{@image_name}:#{@application_name}"
  end
end
