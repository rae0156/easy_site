
module About
   module Constants
      APP_NAME    = 'EasySite'
      
      sub_version = [1,0,5,0]

      case Rails.env.downcase
        when 'development'
          APP_VERSION = 'DEV_'    + sub_version.join('_')
        when 'test'
          APP_VERSION = 'TEST_' + sub_version.join('_')
        else
          APP_VERSION = 'PROD_' + sub_version[0,3].join('_')
      end
      
  end 
end