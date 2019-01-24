# frozen_string_literal: true

module View
  VIEWS_RELATIVE_PATH = '../../views/'
  HAML_EXTENSION = '.html.haml'
  PARTIALS_DIR = 'partials/'
  LAYOUTS_DIR = 'layouts/'
  LAYOUT = 'layout'

  VIEWS = {
    index: 'index',
    game: 'game',
    win: 'win',
    lose: 'lose',
    rules: 'rules',
    statistics: 'statistics'
  }.freeze

  PARTIALS = {
    assets: 'assets',
    errors: 'errors',
    short_description: 'short_description',
    difficulties: 'difficulties',
    game_statistics: 'game_statistics',
    home_btn: 'home_btn',
    play_again_btn: 'play_again_btn',
    statistics_btn: 'statistics_btn'
  }.freeze

  def response_view(view)
    Rack::Response.new(render_layout { render_view(view) })
  end

  def render_partial(partial)
    Haml::Engine.new(File.read(template_path(PARTIALS_DIR + PARTIALS[partial]))).render(binding)
  end

  private

  def render_layout
    Haml::Engine.new(File.read(template_path(LAYOUTS_DIR + LAYOUT))).render(binding)
  end

  def render_view(view)
    Haml::Engine.new(File.read(template_path(VIEWS[view]))).render(binding)
  end

  def template_path(template)
    File.expand_path("#{VIEWS_RELATIVE_PATH}#{template}#{HAML_EXTENSION}", __FILE__)
  end
end
