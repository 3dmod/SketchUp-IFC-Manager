#  IfcShapeRepresentation_su.rb
#
#  Copyright 2017 Jan Brouwer <jan@brewsky.nl>
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

require_relative 'set.rb'
require_relative File.join('IFC2X3', 'IfcFacetedBrep.rb')

module BimTools
  module IfcShapeRepresentation_su
    def initialize(ifc_model, sketchup)
      super
      if sketchup.is_a? Sketchup::ComponentDefinition
        @contextofitems = ifc_model.representationcontext
        @representationidentifier = "'Body'"
        @representationtype = "'Brep'"
        @items = IfcManager::Ifc_Set.new()
      end      
    end # def initialize
  end # module IfcShapeRepresentation_su
end # module BimTools