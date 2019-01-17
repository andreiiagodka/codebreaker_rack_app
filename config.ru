require_relative 'autoload'

use Rack::Reloader
use Rack::Static, urls: ['/assets'], root: './'
use Rack::Session::Cookie, key: 'rack.session', secret: 'password'

run CodebreakerWeb
