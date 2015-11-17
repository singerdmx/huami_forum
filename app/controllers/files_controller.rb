class FilesController < ApplicationController

  protect_from_forgery except: [:create, :destroy]

  def create
    fail "no file in params #{params.inspect}" unless params[:file]
    upload_media(params)
    render json: {success: true}.to_json, status: :ok
  rescue Exception => e
    Rails.logger.error("Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}")
    render json: {message: e.to_s}.to_json, status: :internal_server_error
  end

  private

  def upload_media(params)
    file = params[:file].read

    file_name = params[:file].original_filename
    type = file_name.split('.').last

    media_dir = File.join(File.dirname(__FILE__), "../assets/images/#{type}")
    Dir.mkdir(media_dir) unless File.exists?(media_dir)

    File.open(File.join(media_dir, file_name), 'wb') do |f|
      f.write(file)
    end

    url = request.original_url[0..request.original_url.rindex('/')] + "assets/#{type}/" + file_name
  end

end
