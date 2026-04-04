# encoding: utf-8
require 'redmine'

# Schritt 1: Die Engine laden (optional, aber empfohlen für Rails 7/Redmine 6)
# Erstelle dazu die Datei lib/redmine_drawio/engine.rb wie besprochen
begin
  require_relative 'lib/redmine_drawio/engine'
rescue LoadError
  # Falls die Datei nicht existiert, ignorieren wir es
end

Redmine::Plugin.register :redmine_drawio do
  name 'Redmine Drawio plugin'
  author 'Vincenzo Ampolo'
  description 'Drawio integration for Redmine'
  version '2.0.0'
  url 'https://github.com/vampolo/redmine_drawio'
  
  settings default: {
    'drawio_service_url' => 'https://embed.diagrams.net',
    'drawio_default_format' => 'png'
  }, partial: 'settings/drawio_settings'
end

# Schritt 2: Die gesamte Logik sicher in den Boot-Prozess hängen
# to_prepare sorgt dafür, dass Redmine erst die DB und Core-Klassen lädt
Rails.configuration.to_prepare do
  unless Redmine::Plugin.installed?(:easy_extensions)
    # Hooks laden
    require_dependency 'redmine_drawio/hooks/view_hooks'
    
    # Die after_init.rb genau EINMAL hier drin laden
    after_init_path = File.join(File.dirname(__FILE__), 'after_init.rb')
    require after_init_path if File.exist?(after_init_path)
  end
end