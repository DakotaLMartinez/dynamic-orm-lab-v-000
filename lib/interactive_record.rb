require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    DB[:conn].results_as_hash = true
    
    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end
  
  def col_names_no_id
    self.class.column_names.delete_if {|col| col == "id"}
  end
  
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def values_for_insert
    col_names_no_id.collect do |col_name|
      "'#{send(col_name)}'"
    end.compact.join(", ")
  end
  
  def col_names_for_insert
    col_names_no_id.join(", ")
  end
  
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert
    }) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  def self.find_by(attributes)
    conditions = attributes.collect do |property, value|
      "#{property} = '#{value}'"
    end.join(", ")
    sql = "SELECT * FROM #{table_name} WHERE #{conditions}"
    DB[:conn].execute(sql)
  end
  
  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end
  
end