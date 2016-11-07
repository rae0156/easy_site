require 'set'

# Audit saves the changes to ActiveRecord models.  It has the following attributes:
#
# * <tt>auditable</tt>: the ActiveRecord model that was changed
# * <tt>user</tt>: the user that performed the change; a string or an ActiveRecord model
# * <tt>action</tt>: one of create, update, or delete
# * <tt>changes</tt>: a serialized hash of all the changes
# * <tt>created_at</tt>: Time that the change was performed
#
class Audit < ActiveRecord::Base
  
  belongs_to :auditable, :polymorphic => true
  belongs_to :es_user#, :polymorphic => true
  accepts_nested_attributes_for :es_user
  
  before_create :set_version_number, :set_audit_user

  serialize :changes_audit

  attr_accessible :action, :changes_audit, :process_label, :auditable_type_label, :auditable_label

  cattr_accessor :audited_class_names
  self.audited_class_names = Set.new

  def self.audited_classes
    self.audited_class_names.map(&:constantize)
  end

  # All audits made during the block called will be recorded as made
  # by +user+. This method is hopefully threadsafe, making it ideal
  # for background operations that require audit information.
  def self.as_user(user, &block)
    Thread.current[:acts_as_audited_user] = user

    yield

    Thread.current[:acts_as_audited_user] = nil
  end

  # Allows user to be set to either a string or an ActiveRecord object
  def user_as_string=(user) #:nodoc:
    # reset both either way
    self.user_as_model = self.username = nil
    user.is_a?(ActiveRecord::Base) ?
      self.user_as_model = user :
      self.username = user
  end
  alias_method :user_as_model=, :es_user=
  alias_method :es_user=, :user_as_string=

  def user_as_string #:nodoc:
    self.user_as_model || self.username
  end
  alias_method :user_as_model, :es_user
  alias_method :es_user, :user_as_string

  def revision
    clazz = auditable_type.constantize
    returning clazz.find_by_id(auditable_id) || clazz.new do |m|
      Audit.assign_revision_attributes(m, self.class.reconstruct_attributes(ancestors).merge({:version => version}))
    end
  end

  def ancestors
    self.class.find(:all, :order => 'version',
      :conditions => ['auditable_id = ? and auditable_type = ? and version <= ?',
      auditable_id, auditable_type, version])
  end

  # Returns a hash of the changed attributes with the new values
  def new_attributes
    (changes_audit || {}).inject({}.with_indifferent_access) do |attrs,(attr,values)|
      attrs[attr] = Array(values).last
      attrs
    end
  end

  # Returns a hash of the changed attributes with the old values
  def old_attributes
    (changes_audit || {}).inject({}.with_indifferent_access) do |attrs,(attr,values)|
      attrs[attr] = Array(values).first
      attrs
    end
  end


  def find_new_object_attribute(foreign_key, foreign_id, attribute_to_display='name')
    foreign_key =    foreign_key.gsub('_id','')
    
    auditable_parent  = self.auditable.revision(self.version)
    
    auditable_child   = auditable_parent.send(foreign_key) if auditable_parent.respond_to?(foreign_key)
    
    if auditable_child.respond_to?(attribute_to_display)
      auditable_child.send(attribute_to_display)
    else
      foreign_id
    end
  end

  def self.reconstruct_attributes(audits)
    attributes = {}
    result = audits.collect do |audit|
      attributes.merge!(audit.new_attributes).merge!(:version => audit.version)
      yield attributes if block_given?
    end
    block_given? ? result : attributes
  end
  
  def self.assign_revision_attributes(record, attributes)
    attributes.each do |attr, val|
      if record.respond_to?("#{attr}=")
        record.attributes.has_key?(attr.to_s) ?
          record[attr] = val :
          record.send("#{attr}=", val)
      end
    end
    record
  end

private

  def set_version_number
    max = self.class.maximum(:version,
      :conditions => {
        :auditable_id => auditable_id,
        :auditable_type => auditable_type
        
      }) || 0
    self.version = max + 1
  end

  def set_audit_user
    self.es_user = Thread.current[:acts_as_audited_user] if Thread.current[:acts_as_audited_user]
    nil # prevent stopping callback chains
  end

end