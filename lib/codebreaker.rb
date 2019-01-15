class CodebreakerWeb
  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def response
    case @request.path
    when '/' then return Rack::Response.new(Codebreaker::Console::COMMANDS[:start])
    end
  end
end
