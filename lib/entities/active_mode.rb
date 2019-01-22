class ActiveMode
  include View

  def initialize(request, session)
    @request = request
    @session = session
    @params = @request.params
    @game = @session.get(:game) if @session.present?(:game)
    @errors = []
  end

  def authentication
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
      deactivate_game
      return redirect(:win)
    end

    if @game.loss?
      deactivate_game
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
    return redirect(:game) unless game_deactivated?
    Codebreaker::Statistic.new.save(@session.get(:player), @session.get(:game))
    response_view(:win)
  end

  def lose
    return redirect(:game) unless game_deactivated?
    response_view(:lose)
  end

  private

  def deactivate_game
    @session.set(:game_inactive, true)
  end

  def game_deactivated?
    @session.get(:game_inactive) == true
  end

  def redirect(route)
    Rack::Response.new { |response| response.redirect(CodebreakerRoute::ROUTES[route]) }
  end

  def registrate_player
    player = Codebreaker::Player.new(@params['player_name'])
    validate(player, :player)
  end

  def registrate_difficulty
    difficulty = Codebreaker::Difficulty.new(@params['level'])
    validate(difficulty, :difficulty)
  end

  def registrate_guess
    guess = Codebreaker::Guess.new(@params['guess_code'])
    validate(guess, :guess)
  end

  def validate(entity, session_argument)
    entity.valid? ? @session.set(session_argument, entity) : collect_errors(entity)
  end

  def collect_errors(entity)
    entity.errors.each { |error| @errors << error }
    @session.set(:errors, @errors)
  end

  def valid_credentials?
    @session.get(:errors).empty?
  end
end
