# frozen_string_literal: true

require "tty-command"

class VM
  VAGRANTFILE = %{
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.provision "docker" do |docker|
    docker.build_image "%{build_target_path} -t %{image_tag}"
  end
end
}

  def initialize(application_name)
    @application_name = application_name
  end

  def run
    workdir_path = "/home/ubuntu/instances/#{@application_name}/"
    File.open(workdir_path + "Vagrantfile", "w") do |file|
      file.write(VAGRANTFILE % { build_target_path: "/home/ubuntu/instances/#{@application_name}/deployqa", image_tag: "deployqa:#{@application_name}" })
    end

    TTY::Command.new.run("vagrant up", env: { "VAGRANT_CWD" => workdir_path }) do |output, error|
      puts(output) if output
      puts(error) if error
    end
  end
end
