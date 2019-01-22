class Session
  def initialize(request)
    @session = request.session
  end

  def get(key)
    @session[key]
  end

  def set(key, value)
    @session[key] = value
  end

  def present?(key)
    @session.key?(key)
  end

  def clear
    @session.clear
  end
end
