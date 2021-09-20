require 'fox16'
include Fox


module FXElement

  def initiate_setup(name)
    $fx_elements ||= {}
    if $fx_elements[name]
      fail("Name #{name} is duplicate.")
    end
  end

  class Element
    attr_accessor :value, :object, :name, :placeholder, :set_text, :set_text_color, :set_back_color

    def initialize(object, name)
      @value = nil
      @object = object
      @name = name
      @placeholder = nil
    end

    def set_text(text)
      self.object.text = text
    end

    def set_back_color(color)
      self.object.setBackColor(color)
    end

    def set_text_color(color)
      self.object.setTextColor(color)
    end

    def style_bold
      self.object.setFont(FXFont.new($main_app_window, 'Segoe UI', 10, :weight => FXFont::Bold))
    end

    def style_success
      self.object.setBackColor(FXRGB(3, 183, 63))
      self.object.setTextColor(FXRGB(255, 255, 255))
    end

    def style_danger
      self.object.setBackColor(FXRGB(196, 58, 68))
      self.object.setTextColor(FXRGB(255, 255, 255))
    end

    def style_warning
      self.object.setBackColor(FXRGB(219, 129, 13))
      self.object.setTextColor(FXRGB(255, 255, 255))
    end

    def style_info
      self.object.setBackColor(FXRGB(5, 132, 191))
      self.object.setTextColor(FXRGB(255, 255, 255))
    end


    def style_unselected
      self.object.setBackColor(FXRGB(105, 105, 105))
      self.object.setTextColor(FXRGB(255, 255, 255))
    end

    def style_selected
      self.object.setBackColor(FXRGB(48, 61, 81))
      self.object.setTextColor(FXRGB(255, 255, 255))
    end

    def style_inactive
      self.object.setBackColor(FXRGB(182, 183, 186))
      self.object.setTextColor(FXRGB(255, 255, 255))
    end

    def style_normal_text
      self.object.setBackColor(FXRGB(255, 255, 255))
      self.object.setTextColor(FXRGB(0, 0, 0))
    end

    def style_invalid
      self.object.setBackColor(FXRGB(252, 169, 169))
      self.object.setTextColor(FXRGB(0, 0, 0))
    end

    def style_placeholder
      self.object.setBackColor(FXRGB(255, 255, 255))
      self.object.setTextColor(FXRGB(104, 107, 109))
    end

  end


  def add_file_chooser(parent, name, show_text, pattern_list = [], options = nil)
    initiate_setup(name)
    options_ = options ? options : BUTTON_NORMAL | LAYOUT_CENTER_X
    open_existing_btn = FXButton.new(parent, show_text, :opts => options_)
    $fx_elements[name] = Element.new(open_existing_btn, name)
    $fx_elements[name].style_unselected
    open_existing_btn.connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(parent, "Choose File")
      dialog.patternList = pattern_list.empty? ? ["All Files (*)"] : pattern_list
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        file_name = dialog.filename
        open_existing_btn.text = file_name.split("\\").last
        $fx_elements[name].value = file_name
        $fx_elements[name].style_success
      end
    end
    open_existing_btn
  end

  def add_button(app, name, show_text = 'Button', btn = 'INFO', options = nil, icon_src = nil)
    initiate_setup(name)
    options_ = options ? options : BUTTON_NORMAL
    open_existing_btn = FXButton.new(app, " #{show_text} ", :opts => options_)
    $fx_elements[name] = Element.new(open_existing_btn, name)
    $fx_elements[name].style_bold
    $fx_elements[name].object.icon = create_icon(icon_src) if icon_src
    case btn.upcase
    when 'SUCCESS', 'PASS'
      $fx_elements[name].style_success
    when 'DANGER', 'FAIL'
      $fx_elements[name].style_danger
    when 'WARNING', 'WARN'
      $fx_elements[name].style_warning
    when 'INFO'
      $fx_elements[name].style_info
    else
      nil
    end
    open_existing_btn
  end


  def add_text_field(app, name, size, placeholder = 'Enter a value', options = nil)
    initiate_setup(name)
    options_ = options ? options : TEXTFIELD_NORMAL
    open_existing_txt = FXTextField.new(app, size, :opts => options_|FRAME_SUNKEN|FRAME_THICK)
    $fx_elements[name] = Element.new(open_existing_txt, name)
    $fx_elements[name].style_placeholder
    $fx_elements[name].object.text = placeholder
    $fx_elements[name].placeholder = placeholder
    unless options_ == TEXTFIELD_READONLY
      $fx_elements[name].object.connect(SEL_FOCUSIN) do
        $fx_elements[name].style_normal_text
        $fx_elements[name].object.text = '' if $fx_elements[name].object.text == placeholder
      end
      $fx_elements[name].object.connect(SEL_FOCUSOUT) do
        if $fx_elements[name].object.text == ''
          $fx_elements[name].object.text = placeholder
          $fx_elements[name].style_placeholder
        end
      end
    end
    open_existing_txt
  end

  def add_textarea(app, name, placeholder = 'Enter a value', options = nil, inactive = false, width = 0, height = 0)
    initiate_setup(name)
    options_ = options ? options : TEXT_WORDWRAP
    open_existing_txt = FXText.new(app, :opts => options_, :width => width, :height => height)
    $fx_elements[name] = Element.new(open_existing_txt, name)
    $fx_elements[name].style_placeholder
    $fx_elements[name].object.text = placeholder
    $fx_elements[name].placeholder = placeholder
      $fx_elements[name].object.connect(SEL_FOCUSIN) do
        $fx_elements[name].style_normal_text unless inactive
        $fx_elements[name].object.text = '' if $fx_elements[name].object.text == placeholder
      end
      $fx_elements[name].object.connect(SEL_FOCUSOUT) do
        if $fx_elements[name].object.text == ''
          $fx_elements[name].object.text = placeholder
          $fx_elements[name].style_placeholder unless inactive
        end
      end

    open_existing_txt
  end

  def alert(message, type = 'FAIL')
    case type.upcase
    when 'PASS'
      FXMessageBox.information($app, MBOX_OK, 'Success!', message)
    when 'INFO'
      FXMessageBox.information($app, MBOX_OK, 'Info!', message)  
    when 'CONFIRM'
      FXMessageBox.question($app, MBOX_OK_CANCEL, 'Please Confirm', message)
    else
      FXMessageBox.error($app, MBOX_OK, 'Error Occurred!', message)
    end
  end

  def add_label(app, name, label_text, options = nil)
    initiate_setup(name)
    options_ = options ? options : JUSTIFY_LEFT
    label = FXLabel.new(app, label_text, :opts => options_)
    $fx_elements[name] = Element.new(label, name)
    label
  end

  def add_group_box(app, name, label_text, options = nil)
    initiate_setup(name)
    options_ = options ? options : GROUPBOX_NORMAL
    groupbox = FXGroupBox.new(app, label_text, :opts => options_)
    $fx_elements[name] = Element.new(groupbox, name)
    groupbox
  end

  def add_row(app, name, opts = nil)
    initiate_setup(name)
    opts_ = opts ? opts : LAYOUT_FILL_X
    row = FXHorizontalFrame.new(app, :opts => opts_)
    $fx_elements[name] = Element.new(row, name)
    row
  end

  def add_column(app, name, opts = nil)
    initiate_setup(name)
    opts_ = opts ? opts : LAYOUT_FILL_X
    column = FXVerticalFrame.new(app, :opts => opts_)
    $fx_elements[name] = Element.new(column, name)
    column
  end

  def add_form_text_field(app, name, size, label_text, placeholder = 'Enter a value.', opts = nil)
    initiate_setup(name)
    row = FXHorizontalFrame.new(app)
    FXLabel.new(row, label_text, :opts => JUSTIFY_LEFT)
    opts_ = opts ? opts : TEXTFIELD_NORMAL
    txt = FXTextField.new(row, size, :opts =>  FRAME_SUNKEN|FRAME_THICK|opts_)
    $fx_elements[name] = Element.new(txt, name)
    $fx_elements[name].style_placeholder
    $fx_elements[name].object.text = placeholder
    $fx_elements[name].placeholder = placeholder
    unless opts_ == TEXTFIELD_READONLY
      $fx_elements[name].object.connect(SEL_FOCUSIN) do
        $fx_elements[name].style_normal_text
        $fx_elements[name].object.text = '' if $fx_elements[name].object.text == placeholder
      end
      $fx_elements[name].object.connect(SEL_FOCUSOUT) do
        if $fx_elements[name].object.text == ''
          $fx_elements[name].object.text = placeholder
          $fx_elements[name].style_placeholder
        end
      end
    end
    txt
  end

  def add_form_textarea(app, name, label_text, placeholder = 'Enter a value.')
    initiate_setup(name)
    row = FXHorizontalFrame.new(app)
    FXLabel.new(row, label_text, :opts => JUSTIFY_LEFT)
    txt = FXTextField.new(row, :opts => FRAME_LINE)
    $fx_elements[name] = Element.new(txt, name)
    $fx_elements[name].style_placeholder
    $fx_elements[name].object.text = placeholder
    $fx_elements[name].placeholder = placeholder
    $fx_elements[name].object.connect(SEL_FOCUSIN) do
      $fx_elements[name].style_normal_text
      $fx_elements[name].object.text = '' if $fx_elements[name].object.text == placeholder
    end
    $fx_elements[name].object.connect(SEL_FOCUSOUT) do
      if $fx_elements[name].object.text == ''
        $fx_elements[name].object.text = placeholder
        $fx_elements[name].style_placeholder
      end
    end
    txt
  end

  def add_select(app, name, values = [], options = nil)
    initiate_setup(name)
    options_ = options ? options : LISTBOX_NORMAL | FRAME_LINE
    select = FXListBox.new(app, :opts => options_)
    $fx_elements[name] = Element.new(select, name)
    values.map {|val| $fx_elements[name].object.appendItem(val)} unless values.empty?
    select
  end

  def add_form_select(app, name, label_text, values = [])
    initiate_setup(name)
    row = FXHorizontalFrame.new(app)
    FXLabel.new(row, label_text, :opts => JUSTIFY_LEFT)
    select = FXListBox.new(row, :opts => FRAME_LINE)
    $fx_elements[name] = Element.new(select, name)
    values.map {|val| $fx_elements[name].object.appendItem(val)} unless values.empty?
    select
  end

  def add_checkbox(app, name, label_text)
    initiate_setup(name)
    check = FXCheckButton.new(app, label_text)
    $fx_elements[name] = Element.new(check, name)
    $fx_elements[name].object.connect(SEL_COMMAND) do
      $fx_elements[name].value = $fx_elements[name].object.getCheck
    end
    check
  end

  def add_list(app, name, multi_pick = false, values = [], options = nil, width = 0, height = 0)
    initiate_setup(name)
    multi_pick_ = multi_pick ? LIST_EXTENDEDSELECT : LIST_SINGLESELECT
    options_ = options ? options : FRAME_LINE | LAYOUT_FILL_X
    list = FXList.new(app, :opts => options_ | multi_pick_, :width => width, :height => height)
    $fx_elements[name] = Element.new(list, name)
    values.map {|val| $fx_elements[name].object.appendItem(val)} unless values.empty?
    list
  end

  def add_form_list(app, name, label_text, multi_pick = false, values = [])
    initiate_setup(name)
    multi_pick_ = multi_pick ? LIST_EXTENDEDSELECT : LIST_SINGLESELECT
    row = FXHorizontalFrame.new(app)
    FXLabel.new(row, label_text, :opts => JUSTIFY_LEFT)
    list = FXList.new(row, :opts => FRAME_LINE | multi_pick_)
    $fx_elements[name] = Element.new(list, name)
    values.map {|val| $fx_elements[name].object.appendItem(val)} unless values.empty?
    list
  end

  def add_tab_book(app, name)
    initiate_setup(name)
    tab_book = FXTabBook.new(app)
    $fx_elements[name] = Element.new(tab_book, name)
    tab_book
  end


  def add_tab(tab_bar, name, label_text)
    initiate_setup(name)
    tab = FXTabItem.new(tab_bar, label_text)
    $fx_elements[name] = Element.new(tab, name)
    tab
  end

  def add_form(app, name, num_page, options = nil)
    initiate_setup(name)
    options_ = options ? options : MATRIX_BY_COLUMNS | LAYOUT_FILL_X
    matrix = FXMatrix.new(app, num_page, :opts => options_)
    $fx_elements[name] = Element.new(matrix, name)
    matrix
  end


  def add_composite(app, name)
    initiate_setup(name)
    comp = FXComposite.new(app)
    $fx_elements[name] = Element.new(comp, name)
    comp
  end

  def create_font(font_family = 'Arial', font_size = 10, font_weight = 'NORMAL')
    weight = {'NORAMAL' => {:weight => FXFont::Normal}, 'BOLD' => {:weight => FXFont::Bold}, 'ITALICS' => {:slant => FXFont::Bold}}
    FXFont.new($main_app_window, font_family, font_size, weight["#{font_weight.upcase}"])
  end

  def create_icon(icon_src)
      if icon_src.match /\.png$/i
        FXPNGIcon.new(getApp, File.open(icon_src, 'rb').read)
      elsif icon_src.match /\.jpg$|\.jpeg$/i
        FXJPGIcon.new(getApp, File.open(icon_src, 'rb').read)
      elsif icon_src.match /\.bmp$/i
        FXBMPIcon.new(getApp, File.open(icon_src, 'rb').read)
      elsif icon_src.match /\.gif/i
        FXGIFIcon.new(getApp, File.open(icon_src, 'rb').read)
      else
        fail('Invalid file extension.')
      end
  end

  def register_object(object, name)
    initiate_setup(name)
    $fx_elements[name] = Element.new(object, name)
  end

end

