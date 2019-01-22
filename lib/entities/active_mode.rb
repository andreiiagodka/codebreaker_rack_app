# frozen_string_literal: true

class ActiveMode
  include View

  def initialize(request, session)
    @request = request
    @session = session
    @params = @request.params
    @errors = []
    @game = @session.get(:game) if @session.present?(:game)
  end

  def registration
    registrate_player
    registrate_difficulty
    return redirect(:index) unless valid_credentials?

    @session.set(:game, registrate_game)
    redirect(:game)
  end

  def guess
    registrate_guess
    return redirect(:game) unless valid_credentials?

    return deactivate_game(:win) if @game.win?(@guess.guess_code)
    return deactivate_game(:lose) if @game.loss?

    @game.increment_used_attempts
    @session.set(:marked_guess, @game.mark_guess(@guess.guess_code))
    redirect(:game)
  end

  def hint
    return redirect(:game) if @game.hints_available?

    @session.set(:hints, []) unless @session.present?(:hints)
    @session.get(:hints) << @game.use_hint
    redirect(:game)
  end

  def win
    return redirect(:game) unless game_deactivated?

    Codebreaker::Statistic.new.save(@session.get(:player), @game)
    response_view(:win)
  end

  def lose
    return redirect(:game) unless game_deactivated?

    response_view(:lose)
  end

  def redirect(route)
    Rack::Response.new { |response| response.redirect(CodebreakerRoute::ROUTES[route]) }
  end

  private

  def registrate_player
    player = Codebreaker::Player.new(@params['player_name'])
    validate(player, :player)
  end

  def registrate_difficulty
    @difficulty = Codebreaker::Difficulty.new(@params['level'])
    validate(@difficulty, :difficulty)
  end

  def registrate_game
    Codebreaker::Game.new(@difficulty.level)
  end

  def registrate_guess
    @guess = Codebreaker::Guess.new(@params['guess_code'])
    validate(@guess, :guess)
  end

  def deactivate_game(route)
    @session.set(:game_inactive, true)
    redirect(route)
  end

  def game_deactivated?
    @session.get(:game_inactive) == true
  end

  def validate(entity, session_argument)
    entity.valid? ? @session.set(session_argument, entity) : collect_errors(entity)
  end

  def collect_errors(entity)
    entity.errors.each { |error| @errors << error }
    @session.set(:errors, @errors)
  end

  def valid_credentials?
    @errors.empty?
  end
end
