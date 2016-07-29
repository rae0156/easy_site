require "#{Rails.root}/lib/plugins/acts_as_audited/lib/acts_as_audited/audit.rb"
require "#{Rails.root}/lib/plugins/acts_as_audited/lib/acts_as_audited/audit_sweeper.rb"
require "#{Rails.root}/lib/plugins/acts_as_audited/lib/acts_as_audited.rb"

# Dir["#{Rails.root}/lib/plugins/acts_as_audited/lib/**/*.rb"].each do |file|
# end
ActiveRecord::Base.send :include, CollectiveIdea::Acts::Audited
