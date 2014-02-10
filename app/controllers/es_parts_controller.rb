class EsPartsController < DynamicController
   def initialize()
    @columns_screen=[]
    @columns_screen << {      order: 3,
                       name: "es_template_id",
                       column_name:"template name",
                       type: "integer",
                       foreign: true, 
                       linked_name: "es_template",
                       model_linked: "EsTemplate",
                       display_new: true,
                       display_edit: true,
                       print: true,
                       link_update: false,
                       search: false,
                       dynamic_filter: true,
                       dynamic_search: true,
                       sort: true
                      }
    @columns_screen << {      order: 5,
                       name: "es_template.description",
                       column_name:"template description",
                       type: "string",
                       foreign: false, 
                       linked_name: nil,
                       model_linked: nil,
                       display_new: true,
                       display_edit: true,
                       display_list: true,
                       print: true,
                       link_update: false,
                       search: false,
                       dynamic_filter: false,
                       dynamic_search: false,
                       sort: true
                      }
    @columns_screen << {      order: 6,
                       name: "es_template.es_category.name",
                       column_name:"category name",
                       type: "string",
                       foreign: false, 
                       linked_name: nil,
                       model_linked: nil,
                       display_new: true,
                       display_edit: true,
                       display_list: true,
                       print: true,
                       link_update: false,
                       search: false,
                       dynamic_filter: true,
                       dynamic_search: true,
                       sort: true
                      }
    @columns_screen << {      order: 7,
                       name: "created_at",
                       column_name:"creation",
                       display_new: true,
                       display_edit: true,
                       display_list: true,
                       search: true,
                       dynamic_filter: true,
                       dynamic_search: true
                      }
    @columns_screen << {      name: "nombre",
                       dynamic_filter: true,
                       dynamic_search: true
                      }
    @columns_screen << {      name: "active",
                       dynamic_filter: true,
                       dynamic_search: true
                      }
    @columns_screen << {      name: "valeur",
                       value_list: "1a,2b,3c",
                       dynamic_filter: true,
                       dynamic_search: true
                      }
    super
  end 
end
