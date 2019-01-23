# frozen_string_literal: true

module View
  VIEWS_RELATIVE_PATH = '../../views/'
  HAML_EXTENSION = '.html.haml'
  LAYOUTS_DIR = 'layouts/'

  VIEWS = {
    index: 'index',
    game: 'game',
    win: 'win',
    lose: 'lose',
    rules: 'rules',
    statistics: 'statistics'
  }.freeze

  def response_view(view)
    Rack::Response.new(render_layout { render_view(view) })
  end

  private

  def render_layout
    layout_path =  File.expand_path("#{VIEWS_RELATIVE_PATH}#{LAYOUTS_DIR}layout#{HAML_EXTENSION}", __FILE__)
    Haml::Engine.new(File.read(layout_path)).render(binding)
  end

  def render_view(view)
    view_path = File.expand_path("#{VIEWS_RELATIVE_PATH}#{VIEWS[view]}#{HAML_EXTENSION}", __FILE__)
    Haml::Engine.new(File.read(view_path)).render(binding)
  end
end
