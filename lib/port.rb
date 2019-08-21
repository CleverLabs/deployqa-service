# frozen_string_literal: true

class Port
  @ports = [31001]

  def self.allocate
    (@ports << @ports.last + 1).last
  end
end
