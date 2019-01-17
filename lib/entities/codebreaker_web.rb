class CodebreakerWeb
  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @post = @request.params
    @errors = []
  end

  def response
    case @request.path
    when '/' then return Rack::Response.new(render('menu'))
    when '/rules' then return Rack::Response.new(render('rules'))
    when '/statistics' then return Rack::Response.new(render('statistics'))
    when '/game' then return Rack::Response.new(render('game'))
    when '/authenticate' then return authentication
    end
  end

  def load_statistics
    Codebreaker::Statistic.new.load_statistics
  end

  def authentication
    if @post['player_name'].empty? || @post['level'].empty?
      @request.session[:errors] = @errors << I18n.t('error.player_name_length',
        min_length: Codebreaker::Player::NAME_LENGTH_RANGE.min,
        max_length: Codebreaker::Player::NAME_LENGTH_RANGE.max)
      redirect('/')
    end
  end

  def errors?
    @request.session.key?(:errors)
  end

  def output_errors
    @request.session[:errors]
  end

  def clear_session
    @request.session.clear
  end

  private

  def redirect(route)
    Rack::Response.new { |response| response.redirect(route) }
  end

  def render(template)
    path = File.expand_path("../../views/#{template}.html.haml", __FILE__)
    Haml::Engine.new(File.read(path)).render(binding)
  end
end
