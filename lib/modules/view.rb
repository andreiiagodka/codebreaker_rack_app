# frozen_string_literal: true

module View
  VIEWS_RELATIVE_PATH = '../../views/'
  HAML_EXTENSION = '.html.haml'
  PARTIALS_DIR = 'partials/'
  LAYOUT_PATH =  File.expand_path("#{VIEWS_RELATIVE_PATH}layouts/layout#{HAML_EXTENSION}", __FILE__)

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
    game_statistics: 'game_statistics'
  }.freeze

  def response_view(view)
    Rack::Response.new(render_layout { render_view(view) })
  end

  def render_partial(partial)
    path = File.expand_path("#{VIEWS_RELATIVE_PATH}#{PARTIALS_DIR}#{PARTIALS[partial]}#{HAML_EXTENSION}", __FILE__)
    Haml::Engine.new(File.read(path)).render(binding)
  end

  private

  def render_layout
    Haml::Engine.new(File.read(LAYOUT_PATH)).render(binding)
  end

  def render_view(view)
    path = File.expand_path("#{VIEWS_RELATIVE_PATH}#{VIEWS[view]}#{HAML_EXTENSION}", __FILE__)
    Haml::Engine.new(File.read(path)).render(binding)
  end
end
