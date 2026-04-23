# encoding: UTF-8
require 'redmine'
require 'base64'

module RedmineDrawio
  module Hooks
    class ViewLayoutsBaseBodyTop < Redmine::Hook::ViewListener
      def view_layouts_base_body_top(context = {})
        return unless User.current.admin? && !Setting.rest_api_enabled?
        context[:controller].send(:render_to_string, { partial: 'redmine_drawio/hooks/api_not_enabled_warning' })
      end
    end

    class ViewHooks < Redmine::Hook::ViewListener
      def view_my_account_preferences(context = {})
        context[:controller].send :render_to_string, { partial: 'redmine_drawio/hooks/view_my_account' }
      end

      def view_layouts_base_html_head(context={})
        # Use redmine_url so subdirectory installs work correctly.
        base_path = "#{redmine_url}plugin_assets/redmine_drawio"

        header = <<-EOF
            <script type="text/javascript">//<![CDATA[
                $(function() {
                    if($(".mxgraph").length) {
                        var script = document.createElement('script');
                        script.src = '#{drawio_url.split('?')[0]}/js/viewer-static.min.js';
                        document.head.append(script);
                    }
                });
            //]]></script>
        EOF

        header << "<link rel='stylesheet' media='screen' href='#{base_path}/stylesheets/redmine_drawio/drawioEditor.css' />"
        
        return header unless editable?(context)

        # Inline JS bleibt gleich, da es Variablen definiert
        inline = <<-EOF
            <script type=\"text/javascript\">//<![CDATA[
                var Drawio = {
                  settings: {
                      redmineUrl: '#{redmine_url}',
                      hashCode  : '#{hash_code}',
                      drawioUrl : '#{drawio_url}',
                      DMSF      : #{dmsf_enabled? context},
                      isEasyRedmine: #{easyredmine?},
                      drawioUi  : '#{User.current.pref.drawio_ui}',
                      lang      : '#{User.current.language}'
                  }
                };
            //]]></script>
        EOF

        header << inline
        
        # JS Includes auf direkte Pfade umgestellt, um Propshaft/Hashes zu umgehen
        header << "<script src='#{base_path}/javascripts/redmine_drawio/encoding-indexes.js'></script>"
        header << "<script src='#{base_path}/javascripts/redmine_drawio/encoding.min.js'></script>"
        header << "<script src='#{base_path}/javascripts/redmine_drawio/drawioEditor.js'></script>"
        header << "<script src='#{base_path}/javascripts/redmine_drawio/lang/drawio_jstoolbar-en.js'></script>"
        
        if lang_supported? current_language.to_s.downcase
          header << "<script src='#{base_path}/javascripts/redmine_drawio/lang/drawio_jstoolbar-#{current_language.to_s.downcase}.js'></script>"
        end

        # WICHTIG: drawio_jstoolbar.js nur laden, wenn CKEditor NICHT aktiv ist (für Standard-Editor)
        unless ckeditor_enabled?
          header << "<script src='#{base_path}/javascripts/redmine_drawio/drawio_jstoolbar.js'></script>"
        end
        
        header
      end

      private

      # Hilfsmethode zur Sprachprüfung angepasst auf neue Struktur
      def lang_supported? lang
        return false if lang == 'en'
        # Pfadprüfung im Dateisystem (Container-Pfad)
        path = File.join(Rails.root, "plugins/redmine_drawio/assets/javascripts/redmine_drawio/lang/drawio_jstoolbar-#{lang}.js")
        File.exist?(path)
      end

      def editable?(context)
        return false unless context[:controller]
        if context[:controller].is_a?(WikiController)
          return context[:project].present? && User.current.allowed_to?(:edit_wiki_pages, context[:project])
        end
        if context[:controller].is_a?(NewsController)
          return context[:project].present? && User.current.allowed_to?(:manage_news, context[:project])
        end
        # BoardsController#show embeds the new-message form; MessagesController
        # handles the standalone new-topic and reply pages.
        if context[:controller].is_a?(BoardsController) ||
           context[:controller].is_a?(MessagesController)
          return context[:project].present? && User.current.allowed_to?(:add_messages, context[:project])
        end
        return false unless context[:controller].is_a?(IssuesController)

        if context[:issue].nil?
            return true if context[:journal].nil?
            context[:journal].editable_by?(User.current)
        else
            context[:issue].editable?(User.current)
        end
      end

      def redmine_url
        rootUrl = ActionController::Base.relative_url_root
        rootUrl != nil ? rootUrl+'/' : '/'
      end

      def drawio_url
        DrawioSettings.drawio_url
      end

      def dmsf_enabled?(context)
        return false unless Redmine::Plugin.installed? :redmine_dmsf
        return false unless context[:project] && context[:project].module_enabled?('dmsf')
        true
      end

      def ckeditor_enabled?
        Setting.text_formatting == "CKEditor"
      end

      def easyredmine?
        Redmine::Plugin.installed?(:easy_redmine)
      end

      def hash_code
        return '' unless Setting.rest_api_enabled?
        Base64.encode64(User.current.api_key).gsub(/\n/, '').reverse!
      end
    end
  end
end