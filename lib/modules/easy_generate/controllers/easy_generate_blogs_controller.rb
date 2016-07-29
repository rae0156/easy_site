# encoding: UTF-8

class EasyGenerateBlogsController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :model_level => ['EasyGenerateBlog','EasyGenerateBlogDetail']
                       }
    super
  end  
end
