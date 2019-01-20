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
    when '/guess' then return guess_result
    when '/use_hint' then return use_hint
    end
  end

  def guess_result
    @guess = Codebreaker::Guess.new(@post['guess_code'])
    validate_entity(@guess)
    unless @errors.empty?
      @request.session[:errors] = @errors
      return redirect('/game')
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
    return redirect('/') unless @request.session.key?(:game)
    return redirect('/game') if hints_available?
    @game = @request.session[:game]
    @request.session[:hints] = [] unless session_present?(:hints)
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
      return redirect('/')
    end
    @request.session[:player] = @player
    @request.session[:difficulty] = @difficulty
    @request.session[:game] = Codebreaker::Game.new(@difficulty.level)
    redirect('/game')
  end

  def hints_available?
    @request.session[:game].hints_available?
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

  def clear_errors
    @request.session[:errors].clear
  end

  private

  def session_present?(argument)
    @request.session.key?(argument)
  end

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
