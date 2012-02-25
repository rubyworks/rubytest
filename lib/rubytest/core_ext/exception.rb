class Exception

  def set_assertion(boolean)
    @assertion = boolean
  end unless defined?(:set_assertion)

  def assertion?
    @assertion
  end unless defined?(:assertion?)

  def set_priority(integer)
    @priority = integer.to_i
  end unless defined?(:set_priority)

  def priority
    @priority ||= 0
  end unless defined?(:priority)

end
