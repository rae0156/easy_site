# Include hook code here
require "#{Rails.root}/lib/plugins/acts_as_dynamic_model/lib/acts_as_dynamic_model.rb"
ActiveRecord::Base.send(:include, ActsAsDynamicModel::AddActAsMethods) 
