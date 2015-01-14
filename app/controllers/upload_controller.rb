class UploadController < ApplicationController

  def content

    @typefile = params[:typefile]||'*,[DIR]'
    @parent = params[:dir]||''
    @first = @parent.start_with?('*')
    @parent = @parent[1..-1] if @first 
#    unless File.directory?(File.join(Rails.root,@parent))
#      @parent = Directory.find_by_code(@parent).directory 
#    else
#      @parent = File.join(Rails.root,@parent)
#    end
    @dir = DirContent.new(@parent, @typefile).get_content_upload unless @parent.blank?
    @parent += "/" unless @parent.end_with?('/')

    render :layout => false
  end
  
end