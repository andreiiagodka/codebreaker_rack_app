class Game
  include View

  def initialize(request)
    @request = request
    @session = @request.session
    @post = @request.params
    @errors = []
  end

  def registration
    registrate_player
    registrate_difficulty
    return redirect(:index) unless valid_credentials?

    @request.session[:game] = Codebreaker::Game.new(@request.session[:difficulty].level)
    redirect(:game)
  end

  def guess
    registrate_guess
    return redirect(:game) unless valid_credentials?

    @game = @request.session[:game]
    @guess = @request.session[:guess]

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

  private

  def game_inactive?
    @session[:game_inactive] == true
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

  def registrate_player
    player = Codebreaker::Player.new(@post['player_name'])
    validate(player, :player)
  end

  def registrate_difficulty
    difficulty = Codebreaker::Difficulty.new(@post['level'])
    validate(difficulty, :difficulty)
  end

  def registrate_guess
    guess = Codebreaker::Guess.new(@post['guess_code'])
    validate(guess, :guess)
  end

  def validate(entity, session_argument)
    entity.valid? ? @request.session[session_argument] = entity : collect_errors(entity)
  end

  def collect_errors(entity)
    entity.errors.each { |error| @errors << error }
    @request.session[:errors] = @errors
  end

  def valid_credentials?
    @errors.empty?
  end
end
