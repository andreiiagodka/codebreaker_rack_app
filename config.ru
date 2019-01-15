require_relative 'autoload'

use Rack::Reloader
use Rack::Static, urls: ['/assets'], root: './'

run CodebreakerWeb
