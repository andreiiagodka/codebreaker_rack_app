class Game
  include View

  def initialize(request)
    @request = request
    @session = Session.new(request)
    @post = @request.params
    @game = @session.get(:game) if @session.present?(:game)
    @errors = []
  end

  def registration
    registrate_player
    registrate_difficulty
    return redirect(:index) unless valid_credentials?

    @session.set(:game, Codebreaker::Game.new(@session.get(:difficulty).level))
    redirect(:game)
  end

  def guess
    registrate_guess
    return redirect(:game) unless valid_credentials?

    if @game.win?(@session.get(:guess).guess_code)
      @request.session[:game_inactive] = true
      return redirect(:win)
    end

    if @game.loss?
      @request.session[:game_inactive] = true
      return redirect(:lose)
    end

    @game.increment_used_attempts
    @session.set(:marked_guess, @game.mark_guess(@session.get(:guess).guess_code))
    redirect(:game)
  end

  def hint
    return redirect(:game) if hints_available?
    @session.set(:hints, []) unless @session.present?(:hints)
    @session.get(:hints) << @game.use_hint
    redirect(:game)
  end

  def hints_available?
    @session.get(:game).hints_available?
  end

  def win
    return redirect(:game) unless game_inactive?
    Codebreaker::Statistic.new.save(@session.get(:player), @session.get(:game))
    response_view(:win)
  end

  def lose
    return redirect(:game) unless game_inactive?
    response_view(:lose)
  end

  private

  def game_inactive?
    @session.get(:game_inactive) == true
  end

  def redirect(route)
    Rack::Response.new { |response| response.redirect(CodebreakerRoute::ROUTES[route]) }
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
    entity.valid? ? @session.set(session_argument, entity) : collect_errors(entity)
  end

  def collect_errors(entity)
    entity.errors.each { |error| @errors << error }
    @request.session[:errors] = @errors
  end

  def valid_credentials?
    @errors.empty?
  end
end
