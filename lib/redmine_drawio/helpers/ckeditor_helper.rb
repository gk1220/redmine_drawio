# encoding: utf-8
# Prepended into RedmineCkeditor::WikiFormatting::Helper (see after_init.rb)
# to inject the drawio plugin into every CKEditor instance on Wiki edit pages.
module RedmineDrawio
  module Helpers
    module CkeditorHelper
      # Called by redmine_ckeditor's wikitoolbar_for helper for every Wiki
      # edit form. `super` outputs CKEditor's own JS (application.js bundle).
      # Our addition runs AFTER that in the same <head>, so CKEDITOR is already
      # defined when our script executes, and BEFORE the inline body script that
      # calls CKEDITOR.replace() — which is the correct registration window.
      def heads_for_wiki_formatter
        super

        # Guard against being called multiple times in the same request
        # (e.g. when a page contains several wiki textareas).
        return if @_drawio_ckeditor_injected
        @_drawio_ckeditor_injected = true

        root_url    = ActionController::Base.relative_url_root.to_s
        plugin_base = "#{root_url}/plugin_assets/redmine_drawio/javascripts/redmine_drawio/"

        content_for :header_tags do
          javascript_tag(<<~JS)
            (function() {
              if (typeof CKEDITOR === 'undefined') { return; }

              // Register the external plugin path. addExternal() is idempotent.
              if (!CKEDITOR.plugins.externals || !CKEDITOR.plugins.externals['drawio']) {
                CKEDITOR.plugins.addExternal('drawio', '#{plugin_base}', 'plugin.js');
              }

              // Wrap CKEDITOR.replace() so 'drawio' is in every instance's
              // extraPlugins BEFORE CKEditor resolves its plugin list.
              // This script runs in <head> AFTER ckeditor.js (super adds it
              // first to content_for), so CKEDITOR.replace is already the final
              // function and our wrapper cannot be overwritten by CKEditor init.
              if (!CKEDITOR._drawioReplaceWrapped) {
                CKEDITOR._drawioReplaceWrapped = true;
                var _orig = CKEDITOR.replace;
                CKEDITOR.replace = function(element, config) {
                  config = config || {};
                  var extra = config.extraPlugins || '';
                  if (extra.indexOf('drawio') < 0) {
                    config.extraPlugins = extra ? (extra + ',drawio') : 'drawio';
                  }
                  return _orig.call(this, element, config);
                };
              }

              // Add the toolbar group for every new editor instance.
              if (!CKEDITOR._drawioToolbarListenerRegistered) {
                CKEDITOR._drawioToolbarListenerRegistered = true;
                CKEDITOR.on('instanceCreated', function(evt) {
                  evt.editor.on('configLoaded', function() {
                    var toolbar = evt.editor.config.toolbar;
                    if (Array.isArray(toolbar)) {
                      var hasDrawio = toolbar.some(function(g) {
                        return g && g.name === 'drawio';
                      });
                      if (!hasDrawio) {
                        toolbar.push({
                          name: 'drawio',
                          items: ['btn_drawio_attach', 'btn_drawio_dmsf']
                        });
                      }
                    }
                  });
                });
              }
            })();
          JS
        end
      end
    end
  end
end
