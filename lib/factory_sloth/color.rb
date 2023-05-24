# frozen_string_literal: true

module FactorySloth::Color
  extend self

  def yellow(str)
    colorize(str, 33)
  end

  def light_blue(str)
    colorize(str, 36)
  end

  private

  def colorize(str, color_code)
    return str unless tty?

    "\e[#{color_code}m#{str}\e[0m"
  end

  def tty?
    $stdout.is_a?(IO) && $stdout.tty?
  end
end
