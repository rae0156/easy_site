class Ability
  include CanCan::Ability

  def initialize(user)
    can :index, :site
    no_signed = user.blank?
    
    user ||= EsUser.new 
    if no_signed
      roles=[0]
    else
      roles = user.es_roles.collect(&:id)
    end

    #:manage, :read, :create, :update and :destroy 

    roles.each do |role_id|
      if role_id==0
        es_abilities = EsAbility.where({:include_not_connected => "Y"})
      else
        es_abilities = EsRole.find_by_id(role_id).es_abilities
      end
      es_abilities.each do |ability|
        if ability.controller=="all"
          controllers = [:all]
        else
#          controllers = ability.controller.split(',').select {|m| Object.const_defined?(m)}.collect{|c| c.constantize}  
          controllers = ability.controller.split(',').collect{|c| c.to_sym} 
        end
        unless controllers.blank?
          actions = ability.action.split(',').collect{|a| a.to_sym}
          controllers.each do |c|
            can actions, c
          end
        end
      end
    end
      
#    if user.role? 'admin'
#      can :manage, :all
#    elsif user.es_roles.count == 0  
#      can [:index,:list,:contenttree,:viewtree,:export_csv,:up,:down,:export_pdf,:new,:create,:update,:show_setup,:activate,:show,:edit,:destroy], EsMenu
#      can [:index,:list,:contenttree,:viewtree,:export_csv,:up,:down,:export_pdf,:new,:create,:update,:show_setup,:activate,:show,:destroy], EsPart
#      can :edit, EsPart 
#    end

    #can :dynamic_menu, EsMenu , :name => 'Home'
    #can :edit, EsMenu , :parent_id => nil
    #puts "ici 2 : #{can?(:dynamic_menu , EsMenu.new({:name=> "Home1"})) }"


    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
