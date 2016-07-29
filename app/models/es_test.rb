# encoding: UTF-8

class EsTest < ActiveRecord::Base
  belongs_to :es_page


  
  acts_as_dynamic_model([{:name => "code",
                          :link_update => true,
                          :column_name => "Code",
                          :column_text => "ceci est un test",
                          :label_name => "Code",                          
                          :mandatory => true},
                          {:name              => "dummy_2",
                           :type              => "info",
                           :info              => "Ou",
                           :order => 5
                          },                         
                          {:name              => "test_list",
                           :label_name        => "Test liste",
                           :column_name       => "Test liste",
                           :type => "datess",
                           :value_list        => "1,2,3",
                           :display_list      => false
                           
                          }, 
                         {:name => "test_i",
                          :type => "decimal",
                          :column_text => 'toto'
                           },
                         {:name => "other_field",
                          :mandatory => true},
                         {:name => "es_page_id",
                           :type => "association",
                          :model_linked_field => "action"}
                      ],{:audit_model=>false})
  acts_as_audited :keep_text          => true,
                  :child_attrs => {},
                  :model_audit_label  => "Test".trn,
                  :process_label      => "Changement manuel".trn
 

  def list_test
    {"eee" =>["1","2"]}
  end

end