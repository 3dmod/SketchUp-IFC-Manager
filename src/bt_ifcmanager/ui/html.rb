#  html.rb
#
#  Copyright 2020 Jan Brouwer <jan@brewsky.nl>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
#
# HTML templates

module BimTools
  module IfcManager
    module PropertiesWindow    
      def html_header()
        css_bootstrap = File.join(PLUGIN_PATH_CSS, 'bootstrap.min.css')
        css_core = File.join(PLUGIN_PATH_CSS, 'dialog.css')
        css_select2 = File.join(PLUGIN_PATH_CSS, 'select2.min.css')
        css_entityinfo = File.join(PLUGIN_PATH_CSS, 'entity_info.css')
        
        js_bootstrap = File.join(PLUGIN_PATH, 'js', 'bootstrap.min.js')
        js_jquery = File.join(PLUGIN_PATH, 'js', 'jquery.min.js')
        js_select2 = File.join(PLUGIN_PATH, 'js', 'select2.min.js')
<<HTML
<head>
  <title>Edit IFC properties</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel='stylesheet' type='text/css' href='#{css_bootstrap}'>
  <link rel='stylesheet' type='text/css' href='#{css_core}'>
  <link rel='stylesheet' type='text/css' href='#{css_select2}'>
  <link rel='stylesheet' type='text/css' href='#{css_entityinfo}'>
  <script type='text/javascript' src='#{js_jquery}'></script>
  <script type='text/javascript' src='#{js_select2}'></script>
  <script type='text/javascript' src='#{js_bootstrap}'></script>
</head>
<body>
  <div class="container-fluid">
HTML
      end

      def html_footer(script)
<<HTML
  </div>
  <script>
    $(document).ready(function(){
      #{script}
    });
  </script></body>
HTML
      end
    end # module PropertiesWindow
  end # module IfcManager
end # module BimTools