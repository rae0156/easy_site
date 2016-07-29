# encoding: UTF-8

class EasyGenerateBreadcrumbsController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 2,
                       :model_level => ['EasyGenerateBreadcrumb','EasyGenerateBreadcrumbDetail']
                       }
    super
  end 
  
end
