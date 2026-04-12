# encoding: utf-8
require File.expand_path('../lib/redmine_drawio', __FILE__)

# Prepend CkeditorHelper into redmine_ckeditor's wiki‑formatting helper so that
# our heads_for_wiki_formatter override injects the drawio plugin script into
# every Wiki edit page's <head>.
#
# Direct constant reference (rather than defined?) is intentional: it triggers
# Zeitwerk autoloading when necessary, and raises NameError (caught below) when
# redmine_ckeditor is not installed.
begin
  mod = RedmineCkeditor::WikiFormatting::Helper
  unless mod.ancestors.include?(RedmineDrawio::Helpers::CkeditorHelper)
    mod.prepend(RedmineDrawio::Helpers::CkeditorHelper)
  end
rescue NameError
  # redmine_ckeditor is not installed – nothing to patch, continue silently.
end

