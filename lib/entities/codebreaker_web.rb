class CodebreakerWeb
  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def response
    case @request.path
    when '/' then return Rack::Response.new(render('menu'))
    when '/rules' then return Rack::Response.new(render('rules'))
    when '/statistics' then return Rack::Response.new(render('statistics'))
    end
  end

  def load_statistics
    Codebreaker::Statistic.new.load_statistics
  end

  private

  def render(template)
    path = File.expand_path("../../views/#{template}.html.haml", __FILE__)
    Haml::Engine.new(File.read(path)).render(binding)
  end
end
