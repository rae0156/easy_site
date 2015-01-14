#DRAFT_3_1_0_0 - E6406 - 31-MAR-2014 - improvement audit
class AuditByVersion < ActiveRecord::Base
  set_table_name "V_AUDIT_VERSIONS"

  belongs_to :es_user

end
