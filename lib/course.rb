require 'pry'
class Course

  attr_accessor :id, :name, :department_id

  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS courses (
      id INTEGER PRIMARY KEY,
      name TEXT,
      department_id TEXT
    )
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = "DROP TABLE IF EXISTS courses"
    DB[:conn].execute(sql)
  end

  def self.new_from_db(row)
    self.new.tap do |s|
      s.id = row[0].to_i
      s.name =  row[1]
      s.department_id = row[2].to_i
      end
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM courses
      WHERE name = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql,name).map do |row|
      self.new_from_db(row)
    end.first
  end

  def self.find_all_by_department_id(department_id)
    sql = <<-SQL
      SELECT *
      FROM courses
      WHERE department_id = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql,department_id).map do |row|
      self.new_from_db(row)
    end
  end

  def attribute_values
    [name, department_id]
  end


  def insert
    sql = <<-SQL
      INSERT INTO courses
      (name, department_id)
      VALUES
      (?,?)
    SQL
    DB[:conn].execute(sql, attribute_values)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM courses").flatten.first
  end

  def update
    sql = <<-SQL
      UPDATE courses
      SET name = ?, department_id = ?
      WHERE id = ?
    SQL
    DB[:conn].execute(sql, attribute_values, id)
    end

  def persisted?
    !!self.id
  end

  def save
    persisted? ? update : insert
  end

  def department
    Department.find_by_id(department_id)
  end

  def department=(department)
    @department = department
    self.department_id = @department.id
  end

  def students
    sql = <<-SQL
      SELECT students.name
      FROM students
      JOIN registrations
      ON students.id = registrations.student_id
      JOIN courses
      ON courses.id = registrations.course_id
      WHERE registrations.course_id = ?
    SQL

    student_names = DB[:conn].execute(sql, id).flatten
    student_names.map { |name| Student.find_by_name(name)}
  end

  def add_student(student_object)
    sql = <<-SQL
      INSERT INTO registrations (course_id, student_id)
      VALUES (:id, :student_id)
    SQL

    DB[:conn].execute(sql, id: id, student_id: student_object.id)
  end

end
