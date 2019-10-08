# frozen_string_literal: true

require "tty-command"

class VM
  VAGRANTFILE = %{
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.synced_folder "%{code_path}", "/instance_code"

  config.vm.provision "docker" do |docker|
    docker.build_image "/instance_code/ -t %{image_tag}"
  end
end
}

  def initialize(application_name)
    @application_name = application_name
  end

  def run
    workdir_path = "/root/instances/#{@application_name}/"
    File.open(workdir_path + "Vagrantfile", "w") do |file|
      file.write(VAGRANTFILE % { code_path: "/root/instances/#{@application_name}/deployqa", image_tag: "deployqa:#{@application_name}" })
    end

    TTY::Command.new.run("vagrant up", env: { "VAGRANT_CWD" => workdir_path }) do |output, error|
      puts(output) if output
      puts(error) if error
    end
  end
end
