class Game
  include View

  def initialize(request)
    @request = request
    @session = @request.session
    @post = @request.params
    @errors = []
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

  def hint
    return redirect(:game) if hints_available?
    @game = @request.session[:game]
    @request.session[:hints] = [] unless session_present?(:hints)
    @request.session[:hints] << @game.use_hint
    redirect(:game)
  end

  def hints_available?
    @request.session[:game].hints_available?
  end

  def win
    return redirect(:game) unless game_inactive?
    Codebreaker::Statistic.new.save(@request.session[:player], @request.session[:game])
    response_view(:win)
  end

  def lose
    return redirect(:game) unless game_inactive?
    response_view(:lose)
  end

  def game_inactive?
    @session[:game_inactive] == true
  end

  def validate_entity(entity)
    entity.validate
    entity.errors.each { |error| @errors << error }
  end

  def redirect(route)
    Rack::Response.new { |response| response.redirect(CodebreakerRoute::ROUTES[route]) }
  end

  def session_present?(argument)
    @session.key?(argument)
  end

  def clear_session
    @request.session.clear
  end
end
