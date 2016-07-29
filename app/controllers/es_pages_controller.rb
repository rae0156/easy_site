# encoding: UTF-8

class EsPagesController < DynamicController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Accès aux pages'}
    super
  end 


end
