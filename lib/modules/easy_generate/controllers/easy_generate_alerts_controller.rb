# encoding: UTF-8

class EasyGenerateAlertsController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Alertes'}
    super
  end 
  
end
