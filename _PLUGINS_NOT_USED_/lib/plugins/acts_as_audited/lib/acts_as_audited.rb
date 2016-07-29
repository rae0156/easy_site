# Copyright (c) 2006 Brandon Keepers
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    # Specify this act if you want changes to your model to be saved in an
    # audit table.  This assumes there is an audits table ready.
    #
    #   class User < ActiveRecord::Base
    #     acts_as_audited
    #   end
    #
    # See <tt>CollectiveIdea::Acts::Audited::ClassMethods#acts_as_audited</tt>
    # for configuration options
    module Audited #:nodoc:
      CALLBACKS = [:audit_create, :audit_update, :audit_destroy]

      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        # == Configuration options
        #
        #
        # * +only+ - Only audit the given attributes
        # * +except+ - Excludes fields from being saved in the audit log.
        #   By default, acts_as_audited will audit all but these fields:
        #
        # * +keep_text+ - Set to true if you want to keep ID only and not :name attribute of the object
        # * +non_ror_compliant_keys+ - Used to managed non RoR compliant foreign_keys 
        #
        #     [self.primary_key, inheritance_column, 'lock_version', 'created_at', 'updated_at']
        #   You can add to those by passing one or an array of fields to skip.
        #
        #     class User < ActiveRecord::Base
        #       acts_as_audited :except => :password
        #     end
        # * +protect+ - If your model uses +attr_protected+, set this to false to prevent Rails from
        #   raising an error.  If you declare +attr_accessibe+ before calling +acts_as_audited+, it
        #   will automatically default to false.  You only need to explicitly set this if you are
        #   calling +attr_accessible+ after.
        #
        #     class User < ActiveRecord::Base
        #       acts_as_audited :protect => false
        #       attr_accessible :name
        #     end
        #
        def acts_as_audited(options = {})
          # don't allow multiple calls


          return if self.included_modules.include?(CollectiveIdea::Acts::Audited::InstanceMethods)

          options = {:protect => accessible_attributes.nil?}.merge(options)

          class_attribute :non_audited_columns
          class_attribute :auditing_enabled
          class_attribute :keep_text              #Used to managed literal values instead of IDs
          class_attribute :non_ror_compliant_keys #Used to managed non RoR compliant foreign_keys
          class_attribute :child_attrs      #Used to managed non RoR compliant foreign_keys
          #improvement audit
          class_attribute :model_audit_label      
          class_attribute :process_label
          class_attribute :not_displayed_in_choices      
          class_attribute :remove_blank_nil_compare      
          
          self.keep_text                = (options[:keep_text]              || false)
          self.non_ror_compliant_keys   = (options[:non_ror_compliant_keys] || {})
          self.child_attrs              = (options[:child_attrs]      || {})
          #improvement audit
          self.model_audit_label        = (options[:model_audit_label]        || table_name.singularize.humanize)
          self.process_label            = (options[:process_label]            || "")
          self.not_displayed_in_choices = (options[:not_displayed_in_choices] || false) #to not display into the list of objet for audit view
          self.remove_blank_nil_compare = (options[:remove_blank_nil_compare] || false) #not compare blank vs nil. Ex if value before is nil and value after is blank, so there is no change
          attr_accessor :process_label

          if options[:only]
            except = self.column_names - options[:only].flatten.map(&:to_s)
          else
            except = [self.primary_key, inheritance_column, 'lock_version',
              'created_at', 'updated_at', 'created_on', 'updated_on']
            except |= Array(options[:except]).collect(&:to_s) if options[:except]
          end
          self.non_audited_columns = except

          has_many :audits, :as => :auditable, :order => "#{Audit.quoted_table_name}.version"
          attr_protected :audit_ids if options[:protect]
          Audit.audited_class_names << self.to_s

          after_create  :audit_create if !options[:on] || (options[:on] && options[:on].include?(:create))
          before_update :audit_update if !options[:on] || (options[:on] && options[:on].include?(:update))
          after_destroy :audit_destroy if !options[:on] || (options[:on] && options[:on].include?(:destroy))

          attr_accessor :version

          #improvement audit
          before_save    :init_process_save
          before_destroy :init_process_destroy
                      



          extend CollectiveIdea::Acts::Audited::SingletonMethods
          include CollectiveIdea::Acts::Audited::InstanceMethods

          self.auditing_enabled = true
          
                   
        end
      end

      module InstanceMethods

        #improvement audit
        def init_process_save
          self.process_label = "Manual change" if self.process_label.blank? && self.class.process_label.blank?  
        end
        def init_process_destroy
          self.process_label = "Manuel removal" if self.process_label.blank? && self.class.process_label.blank?  
        end

        # Temporarily turns off auditing while saving.
        def save_without_auditing
          without_auditing { save }
        end

        # Executes the block with the auditing callbacks disabled.
        #
        #   @foo.without_auditing do
        #     @foo.save
        #   end
        #
        def without_auditing(&block)
          self.class.without_auditing(&block)
        end

        # Gets an array of the revisions available
        #
        #   user.revisions.each do |revision|
        #     user.name
        #     user.version
        #   end
        #
        def revisions(from_version = 1)
          audits = self.audits.find(:all, :conditions => ['version >= ?', from_version])
          return [] if audits.empty?
          revision = self.audits.find_by_version(from_version).revision
          Audit.reconstruct_attributes(audits) {|attrs| revision.revision_with(attrs) }
        end

        # Get a specific revision specified by the version number, or +:previous+
        def revision(version)
          revision_with Audit.reconstruct_attributes(audits_to(version))
        end

        def revision_at(date_or_time)
          audits = self.audits.find(:all, :conditions => ["created_at <= ?", date_or_time])
          revision_with Audit.reconstruct_attributes(audits) unless audits.empty?
        end

        def audited_attributes
          tmp_attrs = attributes.except(*non_audited_columns)
          
          #Loop on each attribute to get the value and not the ids
          attrs = {}
          tmp_attrs.each_pair do |attr, value|
            value = value.localtime if value.is_a?(ActiveSupport::TimeWithZone)              
            attrs[attr] = value
            if keep_text and is_a_foreign_key?(attr) 
              attrs["#{parent_class_name(attr)}_text"] = get_attribute(self[attr], attr)
            end
          end unless tmp_attrs.blank? 
          attrs
        end

      protected

        def revision_with(attributes)
          returning self.dup do |revision|
            revision.send :instance_variable_set, '@attributes', self.attributes_before_type_cast
            Audit.assign_revision_attributes(revision, attributes)

            # Remove any association proxies so that they will be recreated
            # and reference the correct object for this revision. The only way
            # to determine if an instance variable is a proxy object is to
            # see if it responds to certain methods, as it forwards almost
            # everything to its target.
            for ivar in revision.instance_variables
              proxy = revision.instance_variable_get ivar
              if !proxy.nil? and proxy.respond_to? :proxy_respond_to?
                revision.instance_variable_set ivar, nil
              end
            end
          end
        end

      private

        def audited_changes
          changed_attributes.except(*non_audited_columns).inject({}) do |changes,(attr, old_value)|
            no_audit = (old_value == self[attr]) || (self.class.remove_blank_nil_compare && old_value.blank? && self[attr].blank?)
            unless no_audit 
              new_value = self[attr]
              if self[attr].is_a?(ActiveSupport::TimeWithZone)
                new_value = new_value.localtime             
                old_value = old_value.localtime unless old_value.nil?                                
              end
              changes[attr] = [old_value, new_value]
              if keep_text and is_a_foreign_key?(attr)
                changes["#{parent_class_name(attr)}_text"] = [get_attribute(old_value , attr, :old),
                                                              get_attribute(self[attr], attr)] #get new value 
              end
            end
            changes
          end
        end
        
        #Return true if the attribute if a foreign_key
        def is_a_foreign_key?(attr)
          ( attr.to_s.include?('_id') or non_ror_compliant_keys[attr.to_sym] ) and self.respond_to?(parent_class_name(attr.to_sym))
        end
        
        def parent_class_name(attr)
          (non_ror_compliant_keys[attr.to_sym] || attr.to_s.gsub('_id','')).to_sym
        end
        
        def get_attribute(id_to_find, parent_attr, type=:new, child_attr=:name)
          parent_attr = parent_attr.to_sym
          parent_name = parent_class_name(parent_attr)          
          child_attr = (child_attrs[parent_name] || child_attr)
          
          value = nil
          
          case type
            when :old
#              obj   = self.send(parent_name)
#              child = obj.class.find(id_to_find) if obj and id_to_find
#              child = Kernel.const_get(parent_name.to_s.classify).find(id_to_find) if id_to_find 

              r = self.class.reflect_on_all_associations.select { |r| r.name == parent_name }
              child = Kernel.const_get(r.first.class_name).find_by_id(id_to_find) if id_to_find 
              value = child.send(child_attr)     if child and child.respond_to?(child_attr)
            when :new
              obj   = self.send(parent_name)
              value = obj.send(child_attr) if obj and obj.respond_to?(child_attr)
          end
          
          return value
        end
        

        def audits_to(version = nil)
          if version == :previous
            version = if self.version
              self.version - 1
            else
              previous = audits.find(:first, :offset => 1,
                :order => "#{Audit.quoted_table_name}.version DESC")
              previous ? previous.version : 1
            end
          end
          audits.find(:all, :conditions => ['version <= ?', version])
        end

        def audit_create
          write_audit(:action => 'create', :changes_audit => audited_attributes)
        end

        def audit_update
          unless (changes = audited_changes).empty?
            write_audit(:action => 'update', :changes_audit => changes)
          end          
        end

        def audit_destroy
          write_audit(:action => 'destroy', :changes_audit =>  audited_attributes)
        end

        #improvement audit
        def write_audit(attrs)
          attrs[:process_label] = self.process_label.blank? ? self.class.process_label : self.process_label 
          attrs[:auditable_type_label] = self.class.model_audit_label.blank? ? self.class.name : self.class.model_audit_label
          model_columns_name = self.class.columns.collect(&:name)
          if self.respond_to?("get_audit_label")
            auditable_label = self.send("get_audit_label")
          else
            ["iso","code","name","id"].each do |col|
              if model_columns_name.include?(col)
                auditable_label = self[col]
                break
              end              
            end          
          end
          attrs[:auditable_label] = auditable_label

          if auditing_enabled && !attrs[:changes_audit].blank?            
            if attrs[:action] == 'destroy'
              tmp = Audit.new attrs
              tmp.auditable_id = self.id
              tmp.auditable_type = self.class.to_s
              tmp.es_user = EsUser.current_user
              tmp.save 
            else  
              tmp = self.audits.new attrs
              tmp.es_user = EsUser.current_user
              tmp.save 
            end
          end
        end
      end # InstanceMethods

      module SingletonMethods
        # Returns an array of columns that are audited.  See non_audited_columns
        def audited_columns
          self.columns.select { |c| !non_audited_columns.include?(c.name) }
        end


        def without_auditing(&block)
          auditing_was_enabled = auditing_enabled
          disable_auditing
          returning(block.call) { enable_auditing if auditing_was_enabled }
        end

        def disable_auditing
          class_attribute :auditing_enabled
          self.auditing_enabled = false
        end

        def enable_auditing
          class_attribute :auditing_enabled
          self.auditing_enabled = true
        end


        #improvement audit
        def process_label=(value)
          self.process_label = value          
        end
        def process_label
          self.process_label          
        end
        def model_audit_label=(value)
          self.model_audit_label = value          
        end
        def model_audit_label
          self.model_audit_label          
        end
        def not_displayed_in_choices=(value)
          self.not_displayed_in_choices = value          
        end
        def not_displayed_in_choices
          self.not_displayed_in_choices          
        end

        # All audit operations during the block are recorded as being
        # made by +user+. This is not model specific, the method is a
        # convenience wrapper around #Audit.as_user.
        def audit_as( user, &block )
          Audit.as_user( user, &block )
        end

      end
    end
  end
end
