class DogesController < ApplicationController

  def new
    @doge = Doge.new
  end

  def create
    doge = Doge.new(doge_params)
    img = doge.generate
    img_base = Base64.encode64(img.to_blob)
    render json: {image: img_base}
  end

  private

  def doge_params
    params.require(:doge).permit(:name)
  end

end