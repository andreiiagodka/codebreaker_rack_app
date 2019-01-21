module View
  VIEWS_PATH = '../../views/'
  HAML_EXTENSION = '.html.haml'

  VIEWS = {
    index: 'index',
    game: 'game',
    win: 'win',
    lose: 'lose',
    rules: 'rules',
    statistics: 'statistics'
  }.freeze

  def self.response(view)
    return Rack::Response.new(render(view))
  end

  private

  def render(view)
    path = File.expand_path(VIEWS_PATH . VIEWS[view] . HAML_EXTENSION, __FILE__)
    Haml::Engine.new(File.read(path)).render(binding)
  end
end
