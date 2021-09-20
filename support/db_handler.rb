require 'sqlite3'
require 'base64'
require File.dirname(__FILE__) + '/encryption.rb'
include Encrypter

module DBHandler


  def set_db_path(db_loc_path, db_unloc_path)
    $db_locked_path = db_loc_path
    $db_unlocked_path = db_unloc_path
  end

  def create_new_db(path)
    db = SQLite3::Database.new(path)
    db.close
    lock_db(path)
  end

  def execute_sql(statement, array = [])
    print(statement)
    begin
      db = open_db($db_locked_path)
      columns, *response = array.empty? ?  db.execute2(statement) : db.execute2(statement, array)
      close_db(db, $db_unlocked_path)
      response.reverse.push(columns).reverse
    rescue Exception => error
      close_db(db, $db_unlocked_path)
      [["Error Occurred. \nClass: #{error.class} \nMessage: #{error.message}"]]
    end
  end

  def open_db(path)
    path_ = unlock_db(path)
    SQLite3::Database.open(path_)
  end

  def close_db(db, path)
    db.close
    lock_db(path)
  end

  def lock_db(path)
    source = path.gsub(/\.enc$/, '.db')
    target = path.gsub(/\.db$/, '.enc')
    cypher_file(source, target, false)
    File.delete(path)
    target
  end

  def unlock_db(path)
    source = path.gsub(/\.db$/, '.enc')
    target = path.gsub(/\.enc$/, '.db')
    cypher_file(source, target, true)
    File.delete(path)
    target
  end

  def get_value_from_matrix(array, key)
    key_index = array[0].find_index(key)
    final_array = []
    array.each_with_index do |val_array, index|
      final_array.push(val_array[key_index]) if key_index and index != 0
    end
    final_array
  end

  def is_text_exists?(table_name, column_name, value)
      query = "SELECT #{column_name} from #{table_name} where #{column_name} = '#{value}'"
      res = execute_sql(query)
      res[1] and !res[1].empty?
  end

  def get_unsalted_field(table_name, column_name)
    query = execute_sql("SELECT SALT, #{column_name} from #{table_name}")
    fnl_arr = []
    if query[1] and !query[1].empty?
      query.each_with_index do |val_arr, index|
        if index != 0
          fnl_arr.push(unmix_salt(val_arr[1], val_arr[0]))
        end
      end
      fnl_arr
    else
      fnl_arr
    end
  end

  def get_next_table_id(table_name, col_name = 'ID')
     max_col_val = execute_sql("select max(#{col_name}) from #{table_name}")
     if max_col_val[1] and max_col_val[0].first !~ /Error Occurred/
       max_val = (max_col_val[1].first).to_i + 1
     else
       max_val = 1
     end
     max_val
  end

  def get_salt
     a_z_values = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
     arr_size = a_z_values.size - 1
     raw_salt = "#{a_z_values[rand(arr_size)]}#{a_z_values[rand(arr_size)]}#{a_z_values[rand(arr_size)]}#{a_z_values[rand(arr_size)]}#{a_z_values[rand(arr_size)]}"
     Base64.encode64(raw_salt)
  end

  def mix_salt(text, salt)
      Base64.encode64(text + salt + text + salt + text)
  end

  def unmix_salt(salted_text, salt)
      Base64.decode64(salted_text).split(salt).first
  end

end