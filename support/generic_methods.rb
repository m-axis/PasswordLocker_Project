module GenericMethods

  def non_blank?(text, placeholder = nil)
     text and text.strip != '' and (placeholder ? text != placeholder : true)
  end

  def blank?(text, placeholder = nil)
    text.nil? or text.empty? or text.strip == '' or (placeholder ? text == placeholder : true)
  end
  

end