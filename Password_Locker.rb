require 'fox16'
require 'digest/sha1'
# puts File.dirname(__FILE__)
require File.dirname(__FILE__) + "/support/FXElements.rb"
require File.dirname(__FILE__) + '/support/gmail_module.rb'
require File.dirname(__FILE__) + '/support/generic_methods.rb'
require File.dirname(__FILE__) + '/support/app_db_setting.rb'
require File.dirname(__FILE__) + '/support/db_handler.rb'
require File.dirname(__FILE__) + '/create_icon_file.rb'

include Fox
include FXElement
include GenericMethods
include GMailModule
include DBHandler
include CreateIcon
AppConfig.new

class PasswordLockerApp < FXMainWindow


  def initialize(app, icon)
    super(app, "Password Locker 3.0.1-Beta", icon, :width => 700, :height => 500)
    $main_app_window = app
    $app = self
    $cookies = {}
    LoginPage.new(self)
  end



  def logout_cleanup_activities
    all_elements_to_clean = ['LockerAddNewUtilityTab_UtilityName',
                             'LockerAddNewUtilityTab_UtilityUserName',
                             'LockerAddNewUtilityTab_UtilityPassword',
                             'LockerAddNewUtilityTab_UtilityConfirmPassword',
                             'LockerUserProfile_ProfileUsername',
                             'LockerUserProfile_ProfileFirstname',
                             'LockerUserProfile_ProfileLastname',
                             'LockerUserProfile_ProfileEmail',
                             'LockerUserProfile_ProfilePassword',
                             'LockerUtilityTab_ShowUsername',
                             'LockerUtilityTab_ShowPassword',
                             'LockerChangeAppPassword_CurrentPassword',
                             'LockerChangeAppPassword_NewPassword',
                             'LockerChangeAppPassword_ConfirmPassword'
    ]
    # $change_password_dialog.hide if $change_password_dialog
    all_elements_to_clean.each do |elem_name|
      if $fx_elements[elem_name] and   $fx_elements[elem_name].object
        $fx_elements[elem_name].object.text = $fx_elements[elem_name].placeholder
        $fx_elements[elem_name].style_placeholder
      end
    end
    $cookies = {}
    $fx_elements['LockerMainWindow_NameRow'].object.hide if $fx_elements['LockerMainWindow_NameRow']
    $fx_elements['LockerMainWindow_TabBook'].object.hide if $fx_elements['LockerMainWindow_TabBook']
    $utility_tab.refresh_utility_list if $utility_tab
    $change_password_dialog.close if $change_password_dialog
    $main_login_form.show if $main_login_form
    $main_login_form.focus if $main_login_form
    $locker_user_active = false
    $app.create
    $app.recalc
  end

  def clear_up_new_user_dialog
    add_new_user_texts = ['LockerAddNewUser_NewUserName',
                          'LockerAddNewUser_NewUserFirstName',
                          'LockerAddNewUser_NewUserLastName',
                          'LockerAddNewUser_NewUserPassword',
                          'LockerAddNewUser_NewUserConfrmPassword',
                          'LockerAddNewUser_NewUserEmail'
    ]
    add_new_user_texts.each do |elem_name|
      if  $fx_elements[elem_name]
        $fx_elements[elem_name].object.text =  $fx_elements[elem_name].placeholder
        $fx_elements[elem_name].style_placeholder
      end
    end
  end

  def verify_user(username, password)
    user_details = execute_sql("SELECT *  FROM USERS WHERE USERNAME like '#{username}'")
    if user_details.kind_of?(Array) and user_details[0][0].match /Error Occurred\./
      alert(user_details[0][0])
      false
    elsif user_details.kind_of?(Array)
      password_ = get_value_from_matrix(user_details, 'password')
      username_ = get_value_from_matrix(user_details, 'username')
      salt = get_value_from_matrix(user_details, 'salt')
      if password_.empty?
        alert('User not found. Sign In to add new user.')
        false
      else
        real_pass = unmix_salt(password_.first, salt.first)
        if username.to_s == username_.first.to_s and real_pass.to_s == password.to_s
          user_id = get_value_from_matrix(user_details, 'id').first
          first_name = get_value_from_matrix(user_details, 'first_name').first
          last_name = get_value_from_matrix(user_details, 'last_name').first
          email = get_value_from_matrix(user_details, 'email').first
          user_audit_dtl = execute_sql("SELECT ACTIVE_USER  FROM USER_AUDIT WHERE USER_ID = #{user_id}")
          if user_audit_dtl[1] and get_value_from_matrix(user_audit_dtl, 'ACTIVE_USER').first.to_s == 'Y'
            $cookies[:user_id] = user_id.to_s
            $cookies[:first_name] = unmix_salt(first_name.to_s, salt.first)
            $cookies[:username] = username.to_s
            $cookies[:last_name] = unmix_salt(last_name.to_s, salt.first)
            $cookies[:email] = unmix_salt(email.to_s, salt.first)
            true
          else
            alert('User is not active. Please go to Activate User tab from Sign In.')
            false
          end
        else
          alert('Invalid username or password.')
          false
        end
      end
    else
      alert('I do not know how to deal with it!')
    end
  end

  def mandatory_field_check(elem_class, field_name)
    if blank?(elem_class.object.text, elem_class.placeholder)
      elem_class.style_invalid
      "#{field_name} can not be blank!\n"
    end
  end

  def update_user_profile_page
    user_details_arr = ['LockerUserProfile_ProfileUsername',
                        'LockerUserProfile_ProfileFirstname',
                        'LockerUserProfile_ProfileLastname',
                        'LockerUserProfile_ProfileEmail',
                        'LockerUserProfile_ProfilePassword']
    user_details_arr.each_with_index do |elem_name, elem_idx|
      if $fx_elements[elem_name]
        $fx_elements[elem_name].object.text = $cookies[:username] if elem_idx == 0
        $fx_elements[elem_name].object.text = $cookies[:first_name] if elem_idx == 1
        $fx_elements[elem_name].object.text = $cookies[:last_name] if elem_idx == 2
        $fx_elements[elem_name].object.text = $cookies[:email] if elem_idx == 3
        $fx_elements[elem_name].object.text = '' if elem_idx == 4
        $fx_elements[elem_name].style_normal_text
      end
    end

  end

  def set_current_user_fname
    if $fx_elements['LockerMainWindow_UserFNameLabel']
       $fx_elements['LockerMainWindow_UserFNameLabel'].object.text = "Hi #{$cookies[:first_name]}"
    end
  end

  def minimum_size_requirement(elem_class, field_name, max_size = 8)
    if non_blank?(elem_class.object.text, elem_class.placeholder)
      if elem_class.object.text.length < max_size
        elem_class.style_invalid
        "#{field_name} should be at least #{max_size} letters!\n"
      end
    end
  end

  def create
    super
    show(PLACEMENT_SCREEN)
  end
end


class LoginPage
  def initialize(parent)
    app_locker = nil
    user_placeholder = 'Enter a username'
    pass_placeholder = ''
    form = add_form(parent, 'LoginPage_Form', 1, MATRIX_BY_COLUMNS | LAYOUT_CENTER_Y | LAYOUT_CENTER_X)
    $main_login_form = form
    user_name = add_form_text_field(form, 'LoginPage_UserName', 30, 'Username:', 'Enter a username')
    password = add_form_text_field(form, 'LoginPage_Password', 30, 'Password: ', '', TEXTFIELD_PASSWD)
    login_buttons_row = add_row(form, 'LoginPage_LoginButtonsRow', LAYOUT_CENTER_X | PACK_UNIFORM_WIDTH)
    login = add_button(login_buttons_row, 'LoginPage_LoginButton', 'Login', 'SUCCESS', BUTTON_NORMAL | LAYOUT_CENTER_X)
    add_new_user_btn = add_button(login_buttons_row, 'LoginPage_AddNewUser', 'Sign In', 'INFO', BUTTON_NORMAL | LAYOUT_CENTER_X)
    recover_row = add_row(form, 'LoginPage_RecoverCredsRow', LAYOUT_CENTER_X | PACK_UNIFORM_WIDTH)
    recover_usr = add_button(recover_row, 'LoginPage_RecoverUsernameBtn', 'Forgot Username', '', BUTTON_DEFAULT )
    recover_usr.setTextColor(FXRGB(89, 66, 244))
    recover_pass = add_button(recover_row, 'LoginPage_RecoverPasswordBtn', 'Forgot Password', '', BUTTON_DEFAULT )
    recover_pass.setTextColor(FXRGB(89, 66, 244))
    $sign_in_dialog = nil
    recover_user_dialog = nil
    recover_pass_dialog = nil
    login.connect(SEL_COMMAND) do
      $cookies = {}
      if non_blank?(user_name.text, user_placeholder) and non_blank?(password.text, pass_placeholder)
        if $app.verify_user(user_name, password)
          $logout_timeout_counter = 30
          $locker_user_active = true
          $fx_elements['LoginPage_UserName'].style_placeholder
          $fx_elements['LoginPage_Password'].style_placeholder
          user_name.text = user_placeholder
          password.text = pass_placeholder
          form.hide
          # form.destroy
          if app_locker
            app_locker.show
            $utility_tab.refresh_utility_list if $utility_tab
          else
            app_locker = LockerMainWindow.new($app)
          end
          $app.set_current_user_fname
          $app.create
          $app.recalc
          $app.update_user_profile_page
        end
      else
        alert('Username and Password are mandatory fields.')
      end
    end

    recover_usr.connect(SEL_COMMAND) do
      if recover_user_dialog.nil?
        recover_user_dialog = RecoverUsername.new($app)
      else
        recover_user_dialog.show
      end
      self.show_recover_user_dialog_box(recover_user_dialog)
    end

    add_new_user_btn.connect(SEL_COMMAND) do
      if $sign_in_dialog.nil?
        $sign_in_dialog = LockerAddNewUser.new($app)
      else
        $sign_in_dialog.show
      end
      self.show_dialog_box($sign_in_dialog)
    end

    recover_pass.connect(SEL_COMMAND) do
      if recover_pass_dialog.nil?
        recover_pass_dialog = RecoverPassword.new($app)
      else
        recover_pass_dialog.show
      end
      self.show_recover_pass_dialog_box(recover_pass_dialog)
    end

  end

  def show_recover_user_dialog_box(recover_dialog)
    @recover_user_action = recover_dialog.execute
    if @recover_user_action == 1
      action_taken = verify_recover_username
      if action_taken == 'SUCCESS'
        alert('An email has been sent to you!', 'PASS')
      else
        alert(action_taken)
        show_recover_user_dialog_box(recover_dialog)
      end
    end
  end



  def show_recover_pass_dialog_box(recover_dialog)
    @recover_pass_action = recover_dialog.execute
    if @recover_pass_action == 1
      action_taken = verify_recover_password
      if action_taken == "SUCCESS"
        alert('Password changed successfully!', 'PASS')
      else
        alert(action_taken)
        show_recover_pass_dialog_box(recover_dialog)
      end
    end
  end

  def verify_recover_username
    response = ''
    email = $fx_elements['RecoverUsername_Email']
    val_email = $app.mandatory_field_check(email, 'Email')
    response += (val_email ? val_email : '')
    if response == ''
      if get_unsalted_field('USERS', 'EMAIL').include?(email.object.text.to_s)
        user_profile = execute_sql("SELECT ID, SALT, USERNAME, EMAIL, FIRST_NAME FROM USERS")
        user_name = ""
        first_name = ""
        salt = ""
        user_profile.each_with_index do |user_arr, index|
          if index != 0
             db_email = unmix_salt(user_arr[3], user_arr[1])
            if db_email.to_s == email.object.text.to_s
              user_name = user_arr[2].to_s
              first_name = user_arr[4].to_s
              salt = user_arr[1].to_s
              break
            end
          end
        end
        if user_name == ''
          'Unknown Error Occurred.'
        else
          real_f_name = unmix_salt(first_name, salt)
          sent_email_to = send_email(email.object.text.to_s, 'Recover username', "Hi #{real_f_name.to_s}\nYour username is: #{user_name}")
          email.object.text = email.placeholder
          if sent_email_to.nil?
            alert('Looks like you are not connected to internet. Please connect and try again.')
          end
          'SUCCESS'
        end
      else
        'Email does not exists in the system.'
      end
    else
      response
    end
  end

  def verify_recover_password
    response = ''
    username = $fx_elements['RecoverPassword_AppUsername']
    sec_code = $fx_elements['RecoverPassword_SecuredCode']
    new_pass = $fx_elements['RecoverPassword_NewPassword']
    confrm_pass = $fx_elements['RecoverPassword_ConfirmPassword']
    val_user = $app.mandatory_field_check(username, 'App Username')
    val_code = $app.mandatory_field_check(sec_code, 'Secured Code')
    val_pass = $app.mandatory_field_check(new_pass, 'New Password')
    val_cpass = $app.mandatory_field_check(confrm_pass, 'Confirm Password')
    val_pass_size = $app.minimum_size_requirement(new_pass, 'New Password')
    response += (val_user ? val_user : '') + (val_code ? val_code : '') + (val_pass ? val_pass : '') + (val_cpass ? val_cpass : '') + (val_pass_size ? val_pass_size : '')
    if response == ''
      if new_pass.object.text == confrm_pass.object.text
        if is_text_exists?('USERS', 'USERNAME', username.object.text.to_s)
          user_resul = execute_sql("SELECT * FROM USERS WHERE USERNAME = '#{username.object.text.to_s}'")
          user_id = get_value_from_matrix(user_resul, 'id').first
          user_salt = get_value_from_matrix(user_resul, 'salt').first
          sec_code_resu = execute_sql("SELECT * FROM USER_AUDIT WHERE USER_ID = #{user_id}")
          saved_sec_code_db = get_value_from_matrix(sec_code_resu, 'SECURED_CODE')
          if sec_code_resu[1] and !sec_code_resu[1].empty?
             if Base64.decode64(saved_sec_code_db.to_s) ==  Base64.decode64(sec_code.object.text.to_s)
               new_salted_pass = mix_salt(new_pass.object.text.to_s, user_salt)
               execute_sql("UPDATE USERS SET PASSWORD = '#{new_salted_pass}' WHERE ID = #{user_id}")
               execute_sql("UPDATE USER_AUDIT SET SECURED_CODE = '#{get_salt}' WHERE USER_ID = #{user_id}")
               username.object.text = username.placeholder
               sec_code.object.text = sec_code.placeholder
               new_pass.object.text = new_pass.placeholder
               confrm_pass.object.text = confrm_pass.placeholder
               'SUCCESS'
             else
               sec_code.style_invalid
               'Secured code is invalid or might have been used already.'
             end

          else
            'Unknown error occurred.'
          end

        else
          username.style_invalid
          'User does not exists in the system.'
        end
      else
        confrm_pass.style_invalid
        'Confirm Password does not match.'
      end
    else
      response
    end
  end

  def show_dialog_box(dialog)
    @user_action = dialog.execute
    if @user_action == 1
      action_taken = self.verify_add_new_user
      if action_taken == 'SUCCESS'
        alert("User Added successfully!\nYour secured code has been sent to your email. \nUse 'Activate User' tab under 'Sign In' to activate your username.", 'PASS')
      else
        alert(action_taken)
        show_dialog_box(dialog)
      end
    end
  end


  def verify_add_new_user
    response = ''
    new_user_name = $fx_elements['LockerAddNewUser_NewUserName']
    new_first_name = $fx_elements['LockerAddNewUser_NewUserFirstName']
    new_last_name = $fx_elements['LockerAddNewUser_NewUserLastName']
    new_password = $fx_elements['LockerAddNewUser_NewUserPassword']
    new_cnfrm_password = $fx_elements['LockerAddNewUser_NewUserConfrmPassword']
    new_email = $fx_elements['LockerAddNewUser_NewUserEmail']
    val_usrname = $app.mandatory_field_check(new_user_name, 'Username')
    val_fname = $app.mandatory_field_check(new_first_name, 'First Name')
    val_lname = $app.mandatory_field_check(new_last_name, 'Last Name')
    val_pass = $app.mandatory_field_check(new_password, 'Password')
    val_cnfm_pass = $app.mandatory_field_check(new_cnfrm_password, 'Confirm Password')
    val_email = $app.mandatory_field_check(new_email, 'Email')
    minimum_password_size = $app.minimum_size_requirement(new_password, 'Password')
    response += val_usrname if val_usrname
    response += val_fname if val_fname
    response += val_lname if val_lname
    response += val_pass if val_pass
    response += val_cnfm_pass if val_cnfm_pass
    response += val_email if val_email
    response += minimum_password_size if minimum_password_size
    if response == ''
      if new_password.object.text == new_cnfrm_password.object.text
        if is_text_exists?('USERS', 'username', new_user_name.object.text) or get_unsalted_field('USERS', 'EMAIL').include?(new_email.object.text)
          'Username or Email is already used. Please try different username.'
        else
          next_id = get_next_table_id('USERS')
          next_id_adt = get_next_table_id('USER_AUDIT')
          prepared_stmnt = 'INSERT INTO USERS (ID, USERNAME, SALT, PASSWORD, FIRST_NAME, LAST_NAME, EMAIL)
                             VALUES (?,?,?,?,?,?,?)'
          salt = get_salt
          salted_fname = mix_salt(new_first_name.object.text, salt)
          salted_lname = mix_salt(new_last_name.object.text, salt)
          salted_pass = mix_salt(new_password.object.text, salt)
          salted_email = mix_salt(new_email.object.text, salt)
          prepared_array = [next_id, new_user_name.object.text, salt, salted_pass, salted_fname, salted_lname, salted_email]
          executed_msg = execute_sql(prepared_stmnt, prepared_array)
          secured_code = get_salt
          usr_adt_stmnt = "INSERT INTO USER_AUDIT (ID, USER_ID, ACTIVE_USER, SECURED_CODE) VALUES (?,?,?,?)"
          usr_adt_arr = [next_id_adt, next_id, 'N', secured_code]
          execute_sql(usr_adt_stmnt, usr_adt_arr)
          sent_email_u = send_email(new_email.object.text, 'Secured Code', "Yor secured code is:  #{secured_code}")
          if sent_email_u.nil?
            alert('Looks like your internet is probably not on. Connect to internet and try again.')
          end
          $app.clear_up_new_user_dialog
          if executed_msg[0].first and executed_msg[0].first.match /Error Occurred/
            executed_msg[0].first
          else
            'SUCCESS'
          end

        end
      else
        new_cnfrm_password.style_invalid
        'Confirm Password does not match.'
      end
    else
      response
    end
  end


end


class LockerMainWindow
  def initialize(parent)
    name_row = add_row(parent, 'LockerMainWindow_NameRow', LAYOUT_FILL_X | LAYOUT_SIDE_TOP | PACK_UNIFORM_WIDTH)
    user_firstname_label = add_label(name_row, 'LockerMainWindow_UserFNameLabel', "Hi #{$cookies[:first_name]}", LAYOUT_LEFT)
    $fx_elements['LockerMainWindow_UserFNameLabel'].style_bold
    logout_button = add_button(name_row, 'LockerMainWindow_NameRowButton', 'Logout', 'PASS', BUTTON_NORMAL | LAYOUT_RIGHT)
    tab_book = add_tab_book(parent, 'LockerMainWindow_TabBook')
    credential_view_tab = add_tab(tab_book, 'LockerMainWindow_CredentialViewTab', 'Utilities')
    $utility_tab = LockerUtilityTab.new(tab_book)
    credential_view_tab.connect(SEL_FOCUSIN) do
      $utility_tab.refresh_utility_list
      $utility_tab.focusin_utilities_tab
    end
    credential_utility_tab = add_tab(tab_book, 'LockerMainWindow_AddUtilityTab', 'Add New Utility')
    LockerAddNewUtilityTab.new(tab_book)
    credential_profile_tab = add_tab(tab_book, 'LockerMainWindow_UserProfileTab', 'My Profile')
    LockerUserProfile.new(tab_book)
    logout_button.connect(SEL_COMMAND) do
      name_row.hide
      tab_book.hide
      $cookies = {}
      $utility_tab.refresh_utility_list
      $main_login_form.show
      $app.logout_cleanup_activities
      $app.create
      $app.recalc
    end
  end

  def show
    $fx_elements['LockerMainWindow_NameRow'].object.show
    $fx_elements['LockerMainWindow_TabBook'].object.show
  end


end

class LockerUtilityTab
  def initialize(parent)
    row = add_row(parent, 'LockerUtilityTab_Row1')
    form = add_form(row, 'LockerUtilityTab_Form', 1, MATRIX_BY_COLUMNS | FRAME_SUNKEN | FRAME_THICK)
    form_1 = add_form(row, 'LockerUtilityTab_Form_1', 1, MATRIX_BY_COLUMNS | FRAME_THICK | LAYOUT_CENTER_Y)
    form_2 = add_form(row, 'LockerUtilityTab_Form_2', 1, MATRIX_BY_COLUMNS | FRAME_THICK | LAYOUT_CENTER_Y)
    row2 = add_row(form, 'LockerUtilityTab_Row2')
    search_field = add_text_field(row2, 'LockerUtilityTab_SearchField', 30, 'Search...')
    search_button = add_button(row2, 'LockerUtilityTab_SearchBtn', 'Search')
    add_label(form, 'LockerUtilityTab_SelectUtilityLable', 'Select a utility first.')
    list = add_list(form, 'LockerUtilityTab_UtilityList', false, [], LAYOUT_EXPLICIT, 300, 370)
    self.refresh_utility_list
    show_hide = add_button(form_1, 'LockerUtilityTab_ShowHide', 'Show')
    show_hide.disable
    edit_button = add_button(form_1, 'LockerUtilityTab_EditButton', 'Edit')
    edit_button.disable
    delete_button = add_button(form_1, 'LockerUtilityTab_Delete', 'Delete', 'DANGER')
    delete_button.disable
    add_row(form_2, 'LockerUtilityTab_FakeRow_1')
    add_label(form_2, 'LockerUtilityTab_UsernameLabel', 'Username:')
    show_user_name = add_text_field(form_2, 'LockerUtilityTab_ShowUsername', 30, '', TEXTFIELD_READONLY)
    add_row(form_2, 'LockerUtilityTab_FakeRow_2')
    add_label(form_2, 'LockerUtilityTab_PasswordLabel', 'Password:')
    show_password = add_text_field(form_2, 'LockerUtilityTab_ShowPassword', 30, '', TEXTFIELD_READONLY)
    add_row(form_2, 'LockerUtilityTab_FakeRow_3')

    search_button.connect(SEL_COMMAND) do
      search_word = search_field.text
      if non_blank?(search_word, 'Search...')
        self.refresh_utility_list(search_word)
      else
        self.refresh_utility_list  
      end  
    end  
    show_hide.connect(SEL_COMMAND) do
      if show_hide.text.strip == 'Show'
        $clicked_show_creds_btn = true
        show_hide.text = ' Clear '
        selected_utility_name = list.getItemText(list.currentItem)
        pair = get_userpass_pair_utility(selected_utility_name)
        if pair
          show_user_name.text = pair[0]
          show_password.text = pair[1]
        end
      else
        show_hide.text = ' Show '
        show_user_name.text = ''
        show_password.text = ''
      end
    end
    list.connect(SEL_SELECTED) do
      show_hide.enable
      delete_button.enable
      edit_button.enable
    end

    list.connect(SEL_KEYPRESS) do
      alert('Click Show to view your credentials.')
    end

    list.connect(SEL_DESELECTED) do
      show_hide.disable
      delete_button.disable
      edit_button.disable
      show_hide.text = ' Show '
      show_user_name.text = ''
      show_password.text = ''
    end
    list.connect(SEL_CHANGED) do
      show_user_name.text = ''
      show_password.text = ''
      show_hide.text = ' Show '
    end

    edit_button.connect(SEL_COMMAND) do
      selected_text = list.getItemText(list.currentItem)
      pair = get_userpass_pair_utility(selected_text)
      $fx_elements['LockerMainWindow_TabBook'].object.setCurrent(1, true)
      $fx_elements['LockerAddNewUtilityTab_UtilityName'].object.text = selected_text
      if pair
        $fx_elements['LockerAddNewUtilityTab_UtilityUserName'].object.text = pair[0]
        $fx_elements['LockerAddNewUtilityTab_UtilityPassword'].object.text = pair[1]
        $fx_elements['LockerAddNewUtilityTab_UtilityConfirmPassword'].object.text = pair[1]
      end
    end

    delete_button.connect(SEL_COMMAND) do
      selected_text = list.getItemText(list.currentItem)
      confirm_delete = alert("Do you want to delete utility - #{selected_text}", 'CONFIRM')
      if confirm_delete == MBOX_CLICKED_OK
        self.delete_utility(selected_text)
        self.refresh_utility_list
      end
    end

  end

  def focusin_utilities_tab
    $fx_elements['LockerUtilityTab_ShowHide'].object.disable
    $fx_elements['LockerUtilityTab_EditButton'].object.disable
    $fx_elements['LockerUtilityTab_Delete'].object.disable
  end

  def delete_utility(utility_name)
    delete_stmnt = "UPDATE UTILITIES SET DELETE_FLAG = ? WHERE ID = ? "
    util_id = self.get_utility_id(utility_name)
    if util_id
      stmnt_arr = ['N', util_id]
      execute_sql(delete_stmnt, stmnt_arr)
      alert("Utility #{utility_name} deleted.", 'PASS')
    else
      alert("Utility not found #{utility_name}")
    end
  end

  def get_utility_id(utility_name)
    query = "SELECT SALT, UTILITY_NAME, ID FROM UTILITIES WHERE USER_ID = ? "
    query_arr = [$cookies[:user_id].to_i]
    query_resu = execute_sql(query, query_arr)
    rtn_util_id = nil
    if query_resu[1]
      query_resu.each_with_index {|val_arr, index|
        if index != 0
          this_utility_ = unmix_salt(val_arr[1], val_arr[0])
          if this_utility_.to_s == utility_name
            rtn_util_id = val_arr[2].to_i
            break
          end
        end
      }
    else
      alert(query_resu[0].first)
    end
    rtn_util_id
  end

  def get_userpass_pair_utility(utility_name)
    query = "SELECT SALT, UTILITY_NAME, UTILITY_USERNAME, UTILITY_PASSWORD FROM UTILITIES WHERE USER_ID = ? AND DELETE_FLAG = ?"
    query_arr = [$cookies[:user_id].to_i, 'Y']
    query_resu = execute_sql(query, query_arr)
    pair_array = nil
    if query_resu[1]
      query_resu.each_with_index {|val_arr, index|
        if index != 0
          this_utility_ = unmix_salt(val_arr[1], val_arr[0])
          this_usrnam_ = unmix_salt(val_arr[2], val_arr[0])
          this_pass_ = unmix_salt(val_arr[3], val_arr[0])
          if this_utility_.to_s == utility_name
            pair_array = [this_usrnam_, this_pass_]
            break
          end
        end
      }
    else
      alert(query_resu[0].first)
    end
    pair_array
  end

  def refresh_utility_list(search_word=nil)
    list = $fx_elements['LockerUtilityTab_UtilityList'].object
    query = "SELECT SALT, UTILITY_NAME, UTILITY_USERNAME, UTILITY_PASSWORD FROM UTILITIES WHERE USER_ID = ? AND DELETE_FLAG = ?"
    query_arr = [$cookies[:user_id].to_i, 'Y']
    list_resu = execute_sql(query, query_arr)
    list.clearItems(true)
    tmp_arr = []
    if list_resu[1]
      list_resu.each_with_index {|vals_arr, index|
        if index != 0
          uti_name = unmix_salt(vals_arr[1], vals_arr[0]).to_s
          if non_blank?(search_word, 'Search...')
            if uti_name.downcase.match  /#{search_word}/ 
              list.appendItem(uti_name)
              tmp_arr.append(uti_name)
            end
          else  
            list.appendItem(uti_name)
            tmp_arr.append(uti_name)
          end  
        end  
      }
    end
    if tmp_arr.length() == 0
       self.refresh_utility_list
       alert("No Match found", "INFO")
    end  
    list.sortItems
  end

end

class LockerAddNewUtilityTab
  def initialize(parent)
    row = add_row(parent, 'LockerAddNewUtilityTab_FormRow')
    form = add_form(row, 'LockerAddNewUtilityTab_Form', 2, MATRIX_BY_COLUMNS | LAYOUT_CENTER_Y | LAYOUT_CENTER_X)
    add_label(form, 'LockerAddNewUtilityTab_UtilityDetailsLabel1', '')
    utility_details_label = add_label(form, 'LockerAddNewUtilityTab_UtilityDetailsLabel2', 'Enter Utility Details')
    utility_details_label.font = create_font('Arial', 15, 'BOLD')
    add_row(form, 'LockerAddNewUtilityTab_FakeRow1')
    add_row(form, 'LockerAddNewUtilityTab_FakeRow2')
    add_label(form, 'LockerAddNewUtilityTab_UtilityLabel', 'Utility Name:')
    utility_name = add_text_field(form, 'LockerAddNewUtilityTab_UtilityName', 30, 'Enter Utility Name')
    add_label(form, 'LockerAddNewUtilityTab_UserNameLabel', 'Utility User Name:')
    user_name = add_text_field(form, 'LockerAddNewUtilityTab_UtilityUserName', 30, 'Enter Utility User Name')
    add_label(form, 'LockerAddNewUtilityTab_PasswordLabel', 'Utility Password:')
    password = add_text_field(form, 'LockerAddNewUtilityTab_UtilityPassword', 30, '', TEXTFIELD_PASSWD)
    add_label(form, 'LockerAddNewUtilityTab_ConfirmPasswordLabel', 'Confirm Utility Password:')
    confirm_password = add_text_field(form, 'LockerAddNewUtilityTab_UtilityConfirmPassword', 30, '', TEXTFIELD_PASSWD)
    add_row(form, 'LockerAddNewUtilityTab_FakeRow3')
    add_utility_btn = add_button(form, 'LockerAddNewUtilityTab_AddUtilityButton', 'Save Utility')
    add_utility_btn.connect(SEL_COMMAND) do
      if !non_blank?(utility_name.text, 'Enter Utility Name')
        alert('Utility Name can not be blank!')
      elsif !non_blank?(user_name.text, 'Enter Utility User Name')
        alert('Utility Username can not be blank!')
      elsif !non_blank?(password.text, 'Enter Utility Password')
        alert('Utility Password can not be blank!')
      elsif !non_blank?(confirm_password.text, 'Enter Utility Confirm Password')
        alert('Confirm Password can not be blank!')
      elsif confirm_password.text != password.text
        alert('Confirm Password does not match!')
      else
        users_utilities = execute_sql("SELECT UTILITY_NAME , SALT, ID FROM UTILITIES WHERE USER_ID = #{$cookies[:user_id].to_i}")
        utility_exists_flag = false
        utility_id = nil
        utility_salt = nil
        if users_utilities[1]
          users_utilities.each_with_index do |val_array, index|
            if index != 0
              this_utility_name = unmix_salt(val_array[0].to_s, val_array[1].to_s).to_s
              if this_utility_name == utility_name.text.to_s
                utility_exists_flag = true
                utility_id = val_array[2].to_i
                utility_salt = val_array[1].to_s
                break
              end
            end
          end
        end
        if utility_exists_flag
          user_confirmation = alert("Utility #{utility_name.text.to_s} exists. Do you want to override this utility?", 'CONFIRM')
          if user_confirmation == MBOX_CLICKED_OK
            prepare_stmnt = "UPDATE UTILITIES SET UTILITY_USERNAME = ? , UTILITY_PASSWORD = ? , DELETE_FLAG = ? WHERE ID = ? "
            if utility_id and utility_salt
              this_utility_user_name = mix_salt(user_name.text.to_s, utility_salt)
              this_utility_pass_word = mix_salt(password.text.to_s, utility_salt)
              prepare_arr = [this_utility_user_name, this_utility_pass_word, 'Y', utility_id]
              updt_resu = execute_sql(prepare_stmnt, prepare_arr)
              utility_name.text = $fx_elements['LockerAddNewUtilityTab_UtilityName'].placeholder
              user_name.text = $fx_elements['LockerAddNewUtilityTab_UtilityUserName'].placeholder
              password.text = $fx_elements['LockerAddNewUtilityTab_UtilityPassword'].placeholder
              confirm_password.text = $fx_elements['LockerAddNewUtilityTab_UtilityConfirmPassword'].placeholder
              alert("Successfully updated utility: #{utility_name.text.to_s}", 'PASS')
            else
              alert('Unknown error occurred.')
            end
          else
            nil
          end
        else
          prepare_stmnt = "INSERT INTO UTILITIES (ID, USER_ID, SALT, UTILITY_NAME, UTILITY_USERNAME, UTILITY_PASSWORD, DELETE_FLAG)
                          VALUES (?,?,?,?,?,?,?)"
          salt_ = get_salt
          this_utility_name = mix_salt(utility_name.text.to_s, salt_)
          this_utility_user_name = mix_salt(user_name.text.to_s, salt_)
          this_utility_pass_word = mix_salt(password.text.to_s, salt_)
          this_id = get_next_table_id('UTILITIES')
          user_id_ = $cookies[:user_id].to_i
          prepare_arr = [this_id, user_id_, salt_, this_utility_name, this_utility_user_name, this_utility_pass_word, 'Y']
          insrt_resu = execute_sql(prepare_stmnt, prepare_arr)
          utility_name.text = $fx_elements['LockerAddNewUtilityTab_UtilityName'].placeholder
          user_name.text = $fx_elements['LockerAddNewUtilityTab_UtilityUserName'].placeholder
          password.text = $fx_elements['LockerAddNewUtilityTab_UtilityPassword'].placeholder
          confirm_password.text = $fx_elements['LockerAddNewUtilityTab_UtilityConfirmPassword'].placeholder
          alert("Successfully added utility: #{utility_name.text.to_s}", 'PASS')

        end
      end
    end
  end
end

class LockerUserProfile
  def initialize(parent)
    row = add_row(parent, 'LockerUserProfile_FormRow')
    form = add_form(row, 'LockerUserProfile_Form', 1, MATRIX_BY_COLUMNS | LAYOUT_CENTER_X | LAYOUT_CENTER_Y)
    add_label(form, 'LockerUserProfile_ProfileDetailsLabel1', '')
    utility_details_label = add_label(form, 'LockerUserProfile_ProfileDetailsLabel2', 'My Profile', LAYOUT_CENTER_X)
    utility_details_label.font = create_font('Arial', 15, 'BOLD')
    user_name = add_form_text_field(form, 'LockerUserProfile_ProfileUsername', 30, 'Username:  ', '', TEXTFIELD_READONLY)
    first_name = add_form_text_field(form, 'LockerUserProfile_ProfileFirstname', 30, "First Name:\s", '')
    last_name = add_form_text_field(form, 'LockerUserProfile_ProfileLastname', 30, 'Last Name: ', '')
    email = add_form_text_field(form, 'LockerUserProfile_ProfileEmail', 30, "Email:\s\s\s\s\s\s\s\s\s\s", '', TEXTFIELD_READONLY)
    password = add_form_text_field(form, 'LockerUserProfile_ProfilePassword', 30, "Password:\s\s\s", '', TEXTFIELD_PASSWD)
    button_row = add_row(form, 'LockerUserProfile_UserInfoButtonsRow', LAYOUT_CENTER_X | PACK_UNIFORM_WIDTH)
    save_user_info = add_button(button_row, 'LockerUserProfile_SaveUserInfo', 'Save Changes', 'SUCCESS', BUTTON_NORMAL)
    change_pwd = add_button(form, 'LockerUserProfile_ChangePasswordBtn', 'Change Password', 'NONE', BUTTON_DEFAULT|LAYOUT_CENTER_X)
    change_pwd.setTextColor(FXRGB(89, 66, 244))
    $change_password_dialog = nil
    change_pwd.connect(SEL_COMMAND) do
      if $change_password_dialog.nil?
        $change_password_dialog = LockerChangeAppPassword.new($app)
      else
        $change_password_dialog.show
      end
      self.show_change_pwd_dialog($change_password_dialog)
    end

    save_user_info.connect(SEL_COMMAND) do
      if non_blank?(password.text)
        if first_name.text == $cookies[:first_name] and last_name.text == $cookies[:last_name] and email.text == $cookies[:email]
          alert('No change to update')
        else
          response = ''
          val_first_name = $app.mandatory_field_check($fx_elements['LockerUserProfile_ProfileFirstname'], 'First Name')
          val_last_name = $app.mandatory_field_check($fx_elements['LockerUserProfile_ProfileLastname'], 'Last Name')
          val_email = $app.mandatory_field_check($fx_elements['LockerUserProfile_ProfileEmail'], 'Email')
          response += (val_first_name ? "#{val_first_name}\n" : '') + (val_last_name ? "#{val_last_name}\n" : '') + (val_email ? "#{val_email}" : '')
          if response == ''
            if $app.verify_user(user_name.text, password.text)
              stmnt = "UPDATE USERS SET SALT = ?, PASSWORD = ?, FIRST_NAME = ? , LAST_NAME = ? , EMAIL = ? WHERE ID = ?"
              new_salt = get_salt
              updt_password = mix_salt(password.text, new_salt)
              updt_first_name = mix_salt(first_name.text, new_salt)
              updt_last_name = mix_salt(last_name.text, new_salt)
              updt_email = mix_salt(email.text, new_salt)
              stmnt_array = [new_salt, updt_password, updt_first_name, updt_last_name, updt_email, $cookies[:user_id]]
              execute_sql(stmnt, stmnt_array)
              $app.verify_user(user_name.text, password.text)
              password.text = ''
              $app.set_current_user_fname
              alert('Successfully updated your profile!', 'PASS')
            else
              alert('Wrong app password. Enter correct app password!')
            end
          else
            alert(response)
          end
        end

      else
        alert('You must enter your password to save the details!')
      end
    end
  end

  def show_change_pwd_dialog(dialog)
    @user_action = dialog.execute
    if @user_action == 1
      action_taken = self.update_user_password
      if action_taken == 'SUCCESS'
        alert('Password changed successfully!', 'PASS')
      else
        alert(action_taken)
        self.show_change_pwd_dialog(dialog)
      end
    end
  end

  def update_user_password
    current_pass = $fx_elements['LockerChangeAppPassword_CurrentPassword']
    new_pass = $fx_elements['LockerChangeAppPassword_NewPassword']
    confirm_pass = $fx_elements['LockerChangeAppPassword_ConfirmPassword']
    response = ''
    val_current_pass = $app.mandatory_field_check(current_pass, 'Current Password')
    val_new_pass = $app.mandatory_field_check(new_pass, 'New Password')
    val_confirm_pass = $app.mandatory_field_check(confirm_pass, 'Confirm Password')
    val_pass_len = $app.minimum_size_requirement(new_pass, 'App New Password')
    response += (val_current_pass ? val_current_pass : '') + (val_new_pass ? val_new_pass : '') + (val_confirm_pass ? val_confirm_pass : '') + (val_pass_len ? val_pass_len : '')
    if response == ''
      if current_pass.object.text == new_pass.object.text
        'New Password can not be same as current.'
      elsif confirm_pass.object.text != new_pass.object.text
        'Confirm password does not match with new password.'
      else
        if $app.verify_user($cookies[:username], current_pass.object.text)
          salted_stuff = execute_sql("select salt from users where id = #{$cookies[:user_id]} ")
          if salted_stuff[1]
            salt = salted_stuff[1].first
            updt_stmnt = "UPDATE USERS SET PASSWORD = ? WHERE ID = ?"
            updt_arr = [mix_salt(new_pass.object.text, salt), $cookies[:user_id]]
            execute_sql(updt_stmnt, updt_arr)
            current_pass.object.text = ''
            new_pass.object.text = ''
            confirm_pass.object.text = ''
            'SUCCESS'
          else
            'Unknown Error Occurred.'
          end
        else
          'Cureent password is incorrect.'
        end
      end
    else
      response
    end
  end

end


class LockerAddNewUser < FXDialogBox
  def initialize(owner)
    super(owner, "Sign In", DECOR_TITLE | DECOR_BORDER | DECOR_RESIZE)
    add_terminating_buttons
    add_tab_book_
  end


  def add_terminating_buttons
    buttons = FXHorizontalFrame.new(self,
                                    :opts => LAYOUT_FILL_X | LAYOUT_SIDE_BOTTOM | PACK_UNIFORM_WIDTH)
    sign_in_btn = FXButton.new(buttons, "Sign In",
                               :target => self, :selector => FXDialogBox::ID_ACCEPT,
                               :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
    register_object(sign_in_btn, 'LockerAddNewUser_DialogSignIn')
    cancel_btn = FXButton.new(buttons, "Cancel",
                              :target => self, :selector => FXDialogBox::ID_CANCEL,
                              :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
    register_object(cancel_btn, 'LockerAddNewUser_DialogCancel')
    $fx_elements['LockerAddNewUser_DialogCancel'].style_danger
    $fx_elements['LockerAddNewUser_DialogCancel'].style_bold
    $fx_elements['LockerAddNewUser_DialogSignIn'].style_success
    $fx_elements['LockerAddNewUser_DialogSignIn'].style_bold
  end


  def add_tab_book_
    # tabbook = FXTabBook.new(self, :opts => LAYOUT_FILL)
    tabbook = add_tab_book(self, :opts => LAYOUT_FILL )
    tab = add_tab(tabbook, 'LockerAddNewUser_AddNewUserTab', 'Add New User')
    form = add_form(tabbook, 'LockerAddNewUser_AddNewUserForm', 1)
    add_form_text_field(form, 'LockerAddNewUser_NewUserName', 30, 'App Username:      ', 'Enter App Username')
    add_form_text_field(form, 'LockerAddNewUser_NewUserFirstName', 30, 'Your First Name:    ', 'Your First Name')
    add_form_text_field(form, 'LockerAddNewUser_NewUserLastName', 30, 'Your Last Name:    ', 'Your Last Name')
    add_form_text_field(form, 'LockerAddNewUser_NewUserPassword', 30, 'Password:               ', '', TEXTFIELD_PASSWD)
    add_form_text_field(form, 'LockerAddNewUser_NewUserConfrmPassword', 30, 'Confirm Password:', '', TEXTFIELD_PASSWD)
    add_form_text_field(form, 'LockerAddNewUser_NewUserEmail', 30, 'Valid Email:             ', 'Your email ID')
    tab2 = add_tab(tabbook, 'LockerAddNewUser_ActivateUserTab', 'Activate User')
    form2 = add_form(tabbook, 'LockerAddNewUser_ActivateUserForm', 1)
    add_form_text_field(form2, 'LockerAddNewUser_ActivateUsername', 30, 'App Username:      ', 'Enter App Username')
    add_form_text_field(form2, 'LockerAddNewUser_ActivateUserMailedCode', 30, 'Secured Message:  ', 'Enter Secured code from email.')
    activate_user_btn = add_button(form2, 'LockerAddNewUser_ActivateUserButton', 'Activate', 'SUCCESS', BUTTON_NORMAL|LAYOUT_CENTER_X)

    tab3 = add_tab(tabbook, 'LockerAddNewUser_SendSecuredCodeTab', 'Get Secured Code')
    form3 = add_form(tabbook, 'LockerAddNewUser_SendSecuredCodeForm', 1)
    add_form_text_field(form3, 'LockerAddNewUser_SendSecuredCodeUsername', 30, 'App Username:', 'Enter App Username')
    # add_form_text_field(form3, 'LockerAddNewUser_SendSecuredCodeEmail', 30, 'Email ID:            ', 'Enter your email ID.')
    send_code_btn = add_button(form3, 'LockerAddNewUser_SendCodeButton', 'Send Code', 'SUCCESS', BUTTON_NORMAL|LAYOUT_CENTER_X)


    tab2.connect(SEL_FOCUSIN) do
      $fx_elements['LockerAddNewUser_DialogSignIn'].object.disable if $fx_elements['LockerAddNewUser_DialogSignIn']
    end

    tab3.connect(SEL_FOCUSIN) do
      $fx_elements['LockerAddNewUser_DialogSignIn'].object.disable if $fx_elements['LockerAddNewUser_DialogSignIn']
    end

    tab.connect(SEL_FOCUSIN) do
      $fx_elements['LockerAddNewUser_DialogSignIn'].object.enable if $fx_elements['LockerAddNewUser_DialogSignIn']
    end

    activate_user_btn.connect(SEL_COMMAND) do
        user_name = $fx_elements['LockerAddNewUser_ActivateUsername']
        sec_code = $fx_elements['LockerAddNewUser_ActivateUserMailedCode']
        response = ''
        val_user =  $app.mandatory_field_check(user_name, 'App Username')
        val_code =  $app.mandatory_field_check(sec_code, 'Secured Message')
        response += (val_user ? val_user : '') + (val_code ? val_code : '')
        if response == ''
          user_id = execute_sql("SELECT ID FROM USERS WHERE USERNAME LIKE '#{user_name.object.text}'")
           if user_id[1]
             sql_res = execute_sql("SELECT SECURED_CODE FROM USER_AUDIT WHERE USER_ID = #{user_id[1].first.to_s}")
             if sql_res[1]
               if Base64.decode64(sec_code.object.text).to_s == Base64.decode64(sql_res[1].first).to_s
                 new_salt = get_salt
                 upt_stmnt = "UPDATE USER_AUDIT SET ACTIVE_USER = 'Y', SECURED_CODE = '#{new_salt}' WHERE USER_ID = #{user_id[1].first.to_s}"
                 execute_sql(upt_stmnt)
                 user_name.object.text = user_name.placeholder
                 sec_code.object.text = sec_code.placeholder
                 alert('User activated. You can now login with your credentials.', 'PASS')
               else
                 alert("Invalid secured code. Please check the secured code.")
               end
             else
               alert('Unknown error. Please contact support.')
             end
           else
             alert('Invalid username.')
           end
        else
          alert(response)
        end
       # $fx_elements['LockerAddNewUser_DialogSignIn'].object.enable if $fx_elements['LockerAddNewUser_DialogSignIn']
    end

    send_code_btn.connect(SEL_COMMAND) do
      user_name = $fx_elements['LockerAddNewUser_SendSecuredCodeUsername']
      response = ''
      val_user =  $app.mandatory_field_check(user_name, 'App Username')
      response += (val_user ? val_user : '')
      if response == ''
        user_id = execute_sql("SELECT ID, SALT, EMAIL FROM USERS WHERE USERNAME LIKE '#{user_name.object.text}'")
        if user_id[1]
          email = unmix_salt((user_id[1][2]).to_s, (user_id[1][1]).to_s)
          new_sec_code = get_salt
          execute_sql("UPDATE USER_AUDIT SET SECURED_CODE = '#{new_sec_code}' WHERE USER_ID = #{user_id[1].first.to_s}")
          sent_email_u = send_email(email, 'Secured Code to activate user', "Your secured code is #{new_sec_code}")
          if sent_email_u
            user_name.object.text = user_name.placeholder
            alert('Secured code has been sent to your email id.', 'PASS')
          else
            alert('Looks like your internet is probably not on. Connect to internet and try again.')
          end
        else
          alert('Invalid username.')
        end
      else
        alert(response)
      end
    end

  end



end


class LockerChangeAppPassword < FXDialogBox
  def initialize(owner)
    super(owner, "Change App Password", DECOR_TITLE | DECOR_BORDER | DECOR_RESIZE)
    add_basic_buttons
    add_change_password_fields
  end


  def add_basic_buttons
    buttons = FXHorizontalFrame.new(self,
                                    :opts => LAYOUT_FILL_X | LAYOUT_SIDE_BOTTOM | PACK_UNIFORM_WIDTH)
    sign_in_btn = FXButton.new(buttons, "Change Password",
                               :target => self, :selector => FXDialogBox::ID_ACCEPT,
                               :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
    register_object(sign_in_btn, 'LockerChangeAppPassword_Change')
    cancel_btn = FXButton.new(buttons, "Cancel",
                              :target => self, :selector => FXDialogBox::ID_CANCEL,
                              :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
    register_object(cancel_btn, 'LockerChangeAppPassword_Cancel')
    $fx_elements['LockerChangeAppPassword_Cancel'].style_danger
    $fx_elements['LockerChangeAppPassword_Cancel'].style_bold
    $fx_elements['LockerChangeAppPassword_Change'].style_success
    $fx_elements['LockerChangeAppPassword_Change'].style_bold
  end


  def add_change_password_fields
    tabbook = FXTabBook.new(self, :opts => LAYOUT_FILL)
    tab = add_tab(tabbook, 'LockerChangeAppPassword_ChangePasswordTab', 'Change Password')
    form = add_form(tabbook, 'LockerChangeAppPassword_ChangePasswordForm', 1)
    add_form_text_field(form, 'LockerChangeAppPassword_CurrentPassword', 30, 'Password:               ', '', TEXTFIELD_PASSWD)
    add_form_text_field(form, 'LockerChangeAppPassword_NewPassword', 30, 'New Password:      ', '', TEXTFIELD_PASSWD)
    add_form_text_field(form, 'LockerChangeAppPassword_ConfirmPassword', 30, 'Confirm Password:', '', TEXTFIELD_PASSWD)
  end
  
  
end


class RecoverUsername < FXDialogBox
  def initialize(owner)
    super(owner, "Recover Username", DECOR_TITLE | DECOR_BORDER | DECOR_RESIZE)
    add_ok_cancel_buttons
    add_recover_credentials_fields
  end

  def add_ok_cancel_buttons
    buttons = FXHorizontalFrame.new(self,
                                    :opts => LAYOUT_FILL_X | LAYOUT_SIDE_BOTTOM | PACK_UNIFORM_WIDTH)
    recover_btn = FXButton.new(buttons, "Recover",
                               :target => self, :selector => FXDialogBox::ID_ACCEPT,
                               :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
    register_object(recover_btn, 'RecoverUsername_RecoverBtn')
    cancel_btn = FXButton.new(buttons, "Cancel",
                              :target => self, :selector => FXDialogBox::ID_CANCEL,
                              :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
    register_object(cancel_btn, 'RecoverUsername_Cancel')
    $fx_elements['RecoverUsername_Cancel'].style_danger
    $fx_elements['RecoverUsername_Cancel'].style_bold
    $fx_elements['RecoverUsername_RecoverBtn'].style_success
    $fx_elements['RecoverUsername_RecoverBtn'].style_bold
  end


  def add_recover_credentials_fields
    tabbook = FXTabBook.new(self, :opts => LAYOUT_FILL)
    tab = add_tab(tabbook, 'RecoverUsername_RecoverUsernameTab', 'Recover Username')
    form = add_form(tabbook, 'RecoverUsername_RecoverUsernameForm', 1)
    add_form_text_field(form, 'RecoverUsername_Email', 30, 'Email:', 'Type your email.')
  end

end



class RecoverPassword < FXDialogBox
  def initialize(owner)
    super(owner, "Recover Password", DECOR_TITLE | DECOR_BORDER | DECOR_RESIZE)
    self.add_ok_cancel_button_
    self.add_recover_password_fields
  end

  def add_ok_cancel_button_
    buttons = FXHorizontalFrame.new(self,
                                    :opts => LAYOUT_FILL_X | LAYOUT_SIDE_BOTTOM | PACK_UNIFORM_WIDTH)
    recover_btn = FXButton.new(buttons, "Recover",
                               :target => self, :selector => FXDialogBox::ID_ACCEPT,
                               :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
    register_object(recover_btn, 'RecoverPassword_RecoverBtn')
    cancel_btn = FXButton.new(buttons, "Cancel",
                              :target => self, :selector => FXDialogBox::ID_CANCEL,
                              :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
    register_object(cancel_btn, 'RecoverPassword_Cancel')
    $fx_elements['RecoverPassword_Cancel'].style_danger
    $fx_elements['RecoverPassword_Cancel'].style_bold
    $fx_elements['RecoverPassword_RecoverBtn'].style_success
    $fx_elements['RecoverPassword_RecoverBtn'].style_bold
  end


  def add_recover_password_fields
    tabbook = FXTabBook.new(self, :opts => LAYOUT_FILL)
    tab = add_tab(tabbook, 'RecoverPassword_RecoverPasswordTab', 'Recover Password')
    form = add_form(tabbook, 'RecoverPassword_RecoverPasswordForm', 1)
    add_form_text_field(form, 'RecoverPassword_AppUsername', 30, 'App Username:      ', 'Type your app username.')
    add_form_text_field(form, 'RecoverPassword_SecuredCode', 30, 'Secured Code:        ', 'Type secured code from email.')
    add_form_text_field(form, 'RecoverPassword_NewPassword', 30, 'New Password:       ', '', TEXTFIELD_PASSWD)
    add_form_text_field(form, 'RecoverPassword_ConfirmPassword', 30, 'Confirm Password:', '', TEXTFIELD_PASSWD)
  end

end


if __FILE__ == $0

  FXApp.new do |app|
    icon_loc = create_icon_file
    icon = FXPNGIcon.new(app, File.open(icon_loc, 'rb').read)
    pwd_lkr = PasswordLockerApp.new(app, icon)
    $logout_timeout_counter ||= 200
    pwd_lkr.connect(SEL_FOCUSIN) do
      $logout_timeout_counter = 30
    end
    pwd_lkr.connect(SEL_FOCUSOUT) do
      $logout_timeout_counter = 12
    end
    app.addTimeout(1 * 10 * 1000, :repeat => true) do
      $logout_timeout_counter -= 1
      if $logout_timeout_counter == 0 and $locker_user_active
        pwd_lkr.logout_cleanup_activities
        alert('For security reasons you got logged out automatically!', 'pass')
      end
      if $clicked_show_creds_btn
        $clicked_show_creds_btn = false
        $fx_elements['LockerUtilityTab_ShowUsername'].object.text = '' if $fx_elements['LockerUtilityTab_ShowUsername']
        $fx_elements['LockerUtilityTab_ShowPassword'].object.text = '' if $fx_elements['LockerUtilityTab_ShowPassword']
        $fx_elements['LockerUtilityTab_ShowHide'].object.text = ' Show ' if $fx_elements['LockerUtilityTab_ShowHide']
      end
    end
    app.create
    app.run
  end

end