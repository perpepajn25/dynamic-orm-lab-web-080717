require 'pry'
require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info(#{self.table_name})"

    table_hash = DB[:conn].execute(sql)
    table_hash.each_with_object([]) do |column, array|
      array << column["name"]
    end.compact
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    self.class.column_names.each_with_object([]) do |col_name, array|
      array << "'#{send(col_name)}'" unless send(col_name).nil?
    end.join(", ")
  end

  def initialize(hash = {})
    hash.each do |key, value|
      self.send("#{key}=",value)
    end
  end

  def save
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
    SQL

    DB[:conn].execute(sql)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by(hash)
    column = hash.keys[0].to_s
    value = hash.keys[0].to_s
    sql = <<-SQL
    SELECT * FROM #{self.table_name} WHERE #{column} = #{value}
    SQL

    DB[:conn].execute(sql)
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name} WHERE name = #{"name"}
    SQL

    DB[:conn].execute(sql)
  end

end
