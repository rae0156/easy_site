#DRAFT_3_1_0_0 - E6406 - 31-MAR-2014 - improvement audit
class AuditByVersion < ActiveRecord::Base
  set_table_name "v_audit_versions"

  belongs_to :es_user

end
