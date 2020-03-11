require_relative "../config/environment.rb"
require 'pry'
require 'active_support/inflector'


class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    #hash of columns names
    #return them as a an array of strings
    column_names = []
    #DB[:conn].results_as_hash = true #not sure that this is needed since it is in the environment file

    sql = "PRAGMA table_info('#{table_name}')" #give you the hash of info
    table_info = DB[:conn].execute(sql)

    table_info.each do |col| #iterate over the array of hashes
      column_names << col["name"] #this gives you the value for the key "name"
    end
    column_names.compact #to get rid of any nulls
  end


  def initialize(options = {}) #pass in a hash
    options.each do |key,value|
      self.send(("#{key}="),value)
    end
  end

  def table_name_for_insert
    #returns the table name when called on an intance of a Student
    self.class.table_name
  end

  def col_names_for_insert
    #return the column names when called on an instance of Student
    #returns it as a string ready to be inserted into a sql statement
    self.class.column_names.delete_if {|column_name| column_name == "id"}.join (", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
  values.join(", ")
  end

  def save
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
    VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  
    #it 'saves the student to the db' do
     # new_student.save
      #expect(DB[:conn].execute("SELECT * FROM students WHERE name = 'Sam'")).to eq([{"id"=>1, "name"=>"Sam", "grade"=>11}])
        #pry(#<Student>)> DB[:conn].execute("SELECT * FROM students WHERE name = 'Sam'")
        #=> [{"id"=>1, "name"=>"Sam", "grade"=>11, 0=>1, 1=>"Sam", 2=>11}]

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    row = DB[:conn].execute(sql,name)
  end

  def self.find_by(attribute)
    #executes the SQL to find a row by the attribute passed into the method
    #WHERE name = ? OR grade = ? OR id = ?
    #attribute is a hash, so it has a key/value pair
    attribute_key = attribute.keys.join()
    attribute_value = attribute.values.first
    sql =<<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{attribute_key} = "#{attribute_value}"
      LIMIT 1
    SQL
    row = DB[:conn].execute(sql)
  end


end