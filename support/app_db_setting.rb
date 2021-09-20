require File.dirname(__FILE__) + '/db_handler.rb'
require 'fileutils'
include DBHandler
class AppConfig

  def initialize
    $user_my_document_dir_files = [ENV['userprofile'] + "\\My Documents\\.appSetting.enc", ENV['userprofile'] + "\\My Documents\\.appSetting.db"]
    set_db_path($user_my_document_dir_files[0], $user_my_document_dir_files[1])
    unless File.exists?($user_my_document_dir_files[0])
      create_new_db($user_my_document_dir_files[1])
      create_db_structure
    end
  end

  def create_db_structure
     print("Creating user table...")
     execute_sql(self.user_table_create)
     print("Creating utility table...")
     execute_sql(self.utility_table_create)
     print("Creating audit table...")
     execute_sql(self.user_audit_table_create)
  end


  def user_table_create
    "CREATE TABLE USERS (
      id INTEGER PRIMARY KEY,
      username text UNIQUE,
      password text,
      salt varchar(255),
      first_name text,
      last_name text,
      email text UNIQUE
       )"
  end
  def utility_table_create
    "CREATE TABLE UTILITIES (
      id INTEGER PRIMARY KEY,
      user_id INTEGER SECONDARY KEY,
      salt varchar(255),
      utility_name text,
      utility_username text,
      utility_password text,
      delete_flag  varchar(10)
      )"
  end

  def user_audit_table_create
    "CREATE TABLE USER_AUDIT
    ( ID INT UNIQUE,
      USER_ID INT SECONDARY KEY,
      ACTIVE_USER VARCHAR(10),
      SECURED_CODE VARCHAR(255)

    )
    "
  end

end

myDb = AppConfig.new
