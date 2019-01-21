class CodebreakerRoute
  include View

  ROUTES = {
    index: '/',
    game: '/game',
    win: '/win',
    lose: '/lose',
    rules: '/rules',
    statistics: '/statistics',
    registration: '/registration',
    hint: '/hint',
    guess: '/guess'
  }.freeze

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @route = @request.path
    @session = @request.session
    @post = @request.params
    @errors = []
  end

  def response
    session_present?(:game) ? active_mode : inactive_mode
  end

  def active_mode
    case @route
    when ROUTES[:game] then View.response(:game)
    when ROUTES[:hint] then hint
    when ROUTES[:guess] then guess
    when ROUTES[:win] then win
    when ROUTES[:lose] then lose
    else redirect(:game)
    end
  end

  def inactive_mode
    case @route
    when ROUTES[:index] then View.response(:index)
    when ROUTES[:rules] then View.response(:rules)
    when ROUTES[:statistics] then View.response(:statistics)
    when ROUTES[:registration] then registration
    else redirect(:index)
    end
  end

  def win
    return redirect(:game) unless game_inactive?
    Codebreaker::Statistic.new.save(@request.session[:player], @request.session[:game])
    View.response(:win)
  end

  def lose
    return redirect(:game) unless game_inactive?
    View.response(:lose)
  end

  def guess
    @guess = Codebreaker::Guess.new(@post['guess_code'])
    validate_entity(@guess)
    unless @errors.empty?
      @request.session[:errors] = @errors
      return redirect(:game)
    end
    @game = @request.session[:game]
    if @game.win?(@guess.guess_code)
      @request.session[:game_inactive] = true
      return redirect(:win)
    end
    if @game.loss?
      @request.session[:game_inactive] = true
      return redirect(:lose)
    end
    @game.increment_used_attempts
    @request.session[:marked_guess] = @game.mark_guess(@guess.guess_code)
    redirect(:game)
  end

  def load_statistics
    Codebreaker::Statistic.new.load_statistics
  end

  def hint
    return redirect(:game) if hints_available?
    @game = @request.session[:game]
    @request.session[:hints] = [] unless session_present?(:hints)
    @request.session[:hints] << @game.use_hint
    redirect(:game)
  end

  def registration
    @player = Codebreaker::Player.new(@post['player_name'])
    validate_entity(@player)
    @difficulty = Codebreaker::Difficulty.new(@post['level'])
    validate_entity(@difficulty)
    unless @errors.empty?
      @request.session[:errors] = @errors
      return redirect(:index)
    end
    @request.session[:player] = @player
    @request.session[:difficulty] = @difficulty
    @request.session[:game] = Codebreaker::Game.new(@difficulty.level)
    redirect(:game)
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

  def session_present?(argument)
    @request.session.key?(argument)
  end

  private

  def game_inactive?
    @session[:game_inactive] == true
  end

  def validate_entity(entity)
    entity.validate
    entity.errors.each { |error| @errors << error }
  end

  def redirect(route)
    Rack::Response.new { |response| response.redirect(ROUTES[route]) }
  end
end
