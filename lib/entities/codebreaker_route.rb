# frozen_string_literal: true

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
    @session = Session.new(@request)
    @active_mode = ActiveMode.new(@request, @session)
    @route = @request.path
  end

  def response
    @session.present?(:game) ? active_mode : inactive_mode
  end

  def active_mode
    case @route
    when ROUTES[:game] then response_view(:game)
    when ROUTES[:guess] then @active_mode.guess
    when ROUTES[:hint] then @active_mode.hint
    when ROUTES[:win] then @active_mode.win
    when ROUTES[:lose] then @active_mode.lose
    else @active_mode.redirect(:game)
    end
  end

  def inactive_mode
    case @route
    when ROUTES[:index] then response_view(:index)
    when ROUTES[:rules] then response_view(:rules)
    when ROUTES[:statistics] then response_view(:statistics)
    when ROUTES[:registration] then @active_mode.registration
    else @active_mode.redirect(:index)
    end
  end
end
