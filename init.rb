# encoding: utf-8
require 'redmine'

base_path = File.dirname(__FILE__)

Redmine::Plugin.register :redmine_drawio do
  name 'Redmine Drawio plugin'
  author 'Michele Tessaro'
  description 'Wiki macro plugin for inserting drawio diagrams into Wiki pages and Issues'
  version '1.6.0'
  url 'https://github.com/gk1220/redmine_drawio'
  author_url 'https://github.com/mikitex70'

  settings default: {
    'drawio_service_url' => 'https://embed.diagrams.net',
    'drawio_default_format' => 'png'
  }, partial: 'settings/drawio_settings'
end

# Load after_init.rb DIRECTLY here — we are already executing inside
# Redmine::PluginLoader's own to_prepare block (see plugin_loader.rb).
# Adding another nested to_prepare from within that block would create a
# new callback that Rails never executes in the same cycle (production: never;
# development: only on the next request, too late).
#
# By requiring directly we run as part of PluginLoader's block, at which point:
#  • redmine_ckeditor's init.rb has already run (alphabetical order), so
#    RedmineCkeditor::WikiFormatting::Helper IS defined.
#  • Ruby's require cache prevents double-loading in production (Zeitwerk
#    has already eager-loaded the files).
unless Redmine::Plugin.installed?(:easy_extensions)
  after_init_path = File.join(base_path, 'after_init.rb')
  require after_init_path if File.exist?(after_init_path)
end