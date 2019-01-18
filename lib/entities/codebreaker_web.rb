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
    when '/game' then return gameflow
    when '/authentication' then return authentication
    when '/use_hint' then return use_hint
    end
  end

  def load_statistics
    Codebreaker::Statistic.new.load_statistics
  end

  def gameflow
    unless @request.session.key?(:game)
      redirect('/')
    end
    return Rack::Response.new(render('game'))
  end

  def use_hint
    unless @request.session.key?(:game)
      redirect('/')
    end
    @game = @request.session[:game]
    @request.session[:hints] = []
    @request.session[:hints] << @game.use_hint
    redirect('/game')
  end

  def authentication
    @player = Codebreaker::Player.new(@post['player_name'])
    validate_entity(@player)
    @difficulty = Codebreaker::Difficulty.new(@post['level'])
    validate_entity(@difficulty)
    unless @errors.empty?
      @request.session[:errors] = @errors
      redirect('/')
    end
    @request.session[:player] = @player
    @request.session[:difficulty] = @difficulty
    @request.session[:game] = Codebreaker::Game.new(@difficulty.level)
    redirect('/game')
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

  def validate_entity(entity)
    entity.validate
    entity.errors.each { |error| @errors << error }
  end

  def redirect(route)
    Rack::Response.new { |response| response.redirect(route) }
  end

  def render(template)
    path = File.expand_path("../../views/#{template}.html.haml", __FILE__)
    Haml::Engine.new(File.read(path)).render(binding)
  end
end
