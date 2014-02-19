class DynamicSearch
  attr_reader :options

  def initialize(model, options)
    @model = model
    @options = options || {}
  end

  def build_conditions
    model=@model

    unless options.empty?

      # note that we're using self.send to make sure we use the getter methods
      options.each_key do |opt|
        opt = opt.to_s
        tmp={}
        if @model.column_names.include?(opt.to_s) || opt.to_s.split('.').count > 1
          tmp_column = @model.columns.select{|column| column.name == opt.to_s}[0]
          tmp[:name] = opt.split('.').count == 1 ? "#{@model.table_name}.#{opt}" : opt 
          value = options[opt.to_sym]
          unless value.nil?
            #tmp[:where]="#{tmp[:name]} IS NULL"
            if opt.to_s.split('.').count > 1
              tmp[:where] = "UPPER(#{opt.to_s.split('.')[-2].pluralize + "." + opt.to_s.split('.').last}) LIKE UPPER(?)" 
              tmp[:value] = "%#{value}%"
              list_table = opt.to_s.split('.')[0..-2].join('.')
              tmp[:includes] = (list_table.blank? ? nil : list_table.split('.').reverse[1..-1].inject(list_table.split('.').last.to_sym) { |b, n| {n.to_sym =>b} })
            elsif ["datetime","date","time"].include?(tmp_column.type.to_s)
              tmp[:where] = "#{tmp[:name]} = ?" 
              tmp[:value] = Time.zone.parse(value).utc.strftime("%Y-%m-%d %H:%M:%S")
            elsif opt =~ /_id$/
              tmp[:where] = "#{tmp[:name]} = ?"
              tmp[:value] = value.to_i
            else
              tmp[:where] = "UPPER(#{tmp[:name]}) LIKE UPPER(?)"
              tmp[:value] = "%#{value}%"
            end
          else
            tmp[:where]="#{tmp[:name]} IS NULL"
          end
        end          

        if tmp[:name].presence
          model = model.includes(tmp[:includes].presence).where(tmp[:where], tmp[:value])
        else
          model = model.where(options[opt.to_sym])
        end
      end
    end
    

    model 
  end

end
    