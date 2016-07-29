# encoding: UTF-8

class EasyGenerateCollapsesController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 2,
                       :model_level => ['EasyGenerateCollapse','EasyGenerateCollapseDetail']
                       }
    super
  end 
  
end
