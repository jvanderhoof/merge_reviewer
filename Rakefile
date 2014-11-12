require "bundler/gem_tasks"
require 'merge_reviewer'
require 'yaml'

namespace :test do
  task :run do
    path = '../masterdev/g3'

    flay = Flayer.new(path)
    puts flay.file_violations('boxes_controller').to_yaml

    flog = Flogger.new(path)
    puts flog.file_violations('spec/controllers/boxes_controller').to_yaml

  end
end
