require 'RMagick' unless defined?(::Magick)

class Doge
  include ActiveModel::Model
  include Magick

  attr_accessor :name

  def generate
    img = Image.read('app/assets/images/doge.jpeg').first
    add_name_to_image(img)
  end

  private

  def self.random_color
    "##{SecureRandom.hex(3)}"
  end

  def add_name_to_image(img)
    name_style.annotate(img, 0,0,0,0, @name)
    img
  end

  def name_style
    name = Draw.new
    name.gravity = CenterGravity
    name.fill = Doge.random_color
    name.pointsize = 180
    name.font_family = 'Arial'
    name.font_weight = BoldWeight
    name.stroke = 'black'
    name.stroke_width = 5
    name
  end

end