module Sample
  module AddActAsMethods
    
    
    def self.included(base)
       puts "ici : before extend AddActAsMethods"
       base.extend(AddActAsMethods)
       puts "ici : after extend AddActAsMethods"
    end
  
  
    def acts_as_sample
      puts "ici : act as sample"    
      puts "ici : before extend all method to #{self.name}"    
      extend AddActAsMethods::ClassMethods
      include AddActAsMethods::InstanceMethods
      puts "ici : after extend all method"    
    end
  
  
  
    module ClassMethods    
  
        puts "ici : multi_site classmethods"    
        def class_proc()
          puts "ici : class_proc"    
          AddActAsMethods.private_proc()
        end
    end
    
    module InstanceMethods
          
      puts "ici : multi_site instancemethods"    
      def instance_proc()
        puts "ici : instance_proc"    
        AddActAsMethods.private_proc()
      end 
    end
  
  
    private 
    
    
    def self.private_proc      
      puts "ici : private_proc"    
    end
  
  end

  puts "ici : before include AddActAsMethods"
  ActiveRecord::Base.send(:include, AddActAsMethods) 
  puts "ici : after include AddActAsMethods"

end
