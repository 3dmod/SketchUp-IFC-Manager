#  IfcCartesianPoint_su.rb
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

require_relative 'IfcReal.rb'

module BimTools
  module IfcCartesianPoint_su
    include IfcManager

    # Creates IfcCartesianPoint entity
    #
    # @parameter ifc_model [BimTools::IfcManager::IfcModel] Model to which the IfcCartesianPoint will be added
    # @parameter sketchup [Geom::Point3d, Geom::Point2d, Array] Takes an Array of length 2 or 3 as coordinates
    #
    def initialize(ifc_model, sketchup)
      super
      case sketchup
      when Geom::Point3d, Geom::Point2d   
        @coordinates = IfcManager::Ifc_List.new(sketchup.to_a.map{|x| IfcManager::IfcReal.new(x.to_mm)})
      else
        raise TypeError, "Expected a point type."
      end
    end
  end
end
