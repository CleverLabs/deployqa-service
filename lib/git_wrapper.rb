# frozen_string_literal: true

require "git"

class GitWrapper
  CODE_FOLDER = "/home/ubuntu/instances/"

  def self.clone_by_uri(application_name, repo_path, repo_uri)
    new(Git.clone(repo_uri, repo_path.split("/").last, path: CODE_FOLDER + application_name))
  end

  def initialize(git_client)
    @git_client = git_client
    @repo_dir = git_client.dir.to_s

    configure_git
  end

  private

  def configure_git
    @git_client.config("user.name", "DeployQA")
    @git_client.config("user.email", "deployqa@cleverlabs.io")
    @git_client.config("commit.gpgsign", "false")
  end
end
