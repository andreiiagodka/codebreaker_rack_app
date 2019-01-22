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
    @game = Game.new(@request)
    @route = @request.path
    @session = @request.session
  end

  def response
    session_present?(:game) ? active_mode : inactive_mode
  end

  def active_mode
    case @route
    when ROUTES[:game] then response_view(:game)
    when ROUTES[:guess] then @game.guess
    when ROUTES[:hint] then @game.hint
    when ROUTES[:win] then @game.win
    when ROUTES[:lose] then @game.lose
    else redirect(:game)
    end
  end

  def inactive_mode
    case @route
    when ROUTES[:index] then response_view(:index)
    when ROUTES[:rules] then response_view(:rules)
    when ROUTES[:statistics] then response_view(:statistics)
    when ROUTES[:registration] then @game.registration
    else redirect(:index)
    end
  end

  def load_statistics
    Codebreaker::Statistic.new.load_statistics
  end

  def errors
    @request.session[:errors]
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

  def redirect(route)
    Rack::Response.new { |response| response.redirect(ROUTES[route]) }
  end
end
