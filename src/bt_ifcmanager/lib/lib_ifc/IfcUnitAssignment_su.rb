#  IfcUnitAssignment_su.rb
#
#  Copyright 2021 Jan Brouwer <jan@brewsky.nl>
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

require_relative 'IfcInteger'

module BimTools
  module IfcUnitAssignment_su
    attr_reader :length_unit, :area_unit, :volume_unit

    include BimTools::IfcManager::Settings.ifc_module

    LENGTH_UNITS = %i[
      Inches
      Feet
      Millimeter
      Centimeter
      Meter
      Yard
    ].freeze

    AREA_UNITS = %i[
      SquareInches
      SquareFeet
      SquareMillimeter
      SquareCentimeter
      SquareMeter
      SquareYard
    ].freeze

    VOLUME_UNITS = %i[
      CubicInches
      CubicFeet
      CubicMillimeter
      CubicCentimeter
      CubicMeter
      CubicYard
      Liter
      USGallon
    ].freeze

    IFC_UNITS = {
      CubicMillimeter: %i[volumeunit milli cubic_metre],
      CubicCentimeter: %i[volumeunit centi cubic_metre],
      CubicMeter: [:volumeunit, '*', :cubic_metre],
      Liter: %i[volumeunit deci cubic_metre],
      Millimeter: %i[lengthunit milli metre],
      Centimeter: %i[lengthunit centi metre],
      Meter: [:lengthunit, '*', :metre],
      SquareMillimeter: %i[areaunit milli square_metre],
      SquareCentimeter: %i[areaunit centi square_metre],
      SquareMeter: [:areaunit, '*', :square_metre]
    }

    CONVERSIONBASEDUNITS = {
      SquareYard: [:SquareMeter, :areaunit, 'SQUARE YARD', 0.83612736, [2, 0, 0, 0, 0, 0, 0]],
      CubicInches: [:CubicMeter, :volumeunit, 'CUBIC INCH', 1.6387064e-05, [3, 0, 0, 0, 0, 0, 0]],
      CubicFeet: [:CubicMeter, :volumeunit, 'CUBIC FOOT', 0.028316846592, [3, 0, 0, 0, 0, 0, 0]],
      CubicYard: [:CubicMeter, :volumeunit, 'CUBIC YARD', 0, 764_554_857_984, [3, 0, 0, 0, 0, 0, 0]],
      USGallon: [:CubicMeter, :volumeunit, 'US GALLON', 0.00378541178, [3, 0, 0, 0, 0, 0, 0]],
      Inches: [:Meter, :lengthunit, 'INCH', 0.0254, [1, 0, 0, 0, 0, 0, 0]],
      Feet: [:Meter, :lengthunit, 'FOOT', 0.3048, [1, 0, 0, 0, 0, 0, 0]],
      Yard: [:Meter, :lengthunit, 'YARD', 0.9144, [1, 0, 0, 0, 0, 0, 0]],
      SquareInches: [:SquareMeter, :areaunit, 'SQUARE INCH', 0.00064516, [2, 0, 0, 0, 0, 0, 0]],
      SquareFeet: [:SquareMeter, :areaunit, 'SQUARE FOOT', 0.09290304, [2, 0, 0, 0, 0, 0, 0]]
    }

    def initialize(ifc_model)
      super
      @ifc_model = ifc_model
      @su_model = ifc_model.su_model
      set_units
      @units = IfcManager::Ifc_Set.new
      @units.add(ifc_unit(@length_unit))
      @units.add(ifc_unit(@area_unit))
      @units.add(ifc_unit(@volume_unit))
    end

    def set_units
      unit_options = @su_model.options['UnitsOptions']
      @length_unit = LENGTH_UNITS[unit_options['LengthUnit']]
      @area_unit = AREA_UNITS[unit_options['AreaUnit']]
      @volume_unit = VOLUME_UNITS[unit_options['VolumeUnit']]
    end

    def ifc_unit(unit_type)
      if IFC_UNITS.key? unit_type
        unit_values = IFC_UNITS[unit_type]
        unit = IfcSIUnit.new(@ifc_model)
        unit.dimensions = '*'
        unit.unittype = unit_values[0]
        unit.prefix = unit_values[1]
        unit.name = unit_values[2]
        unit
      else
        unit_values = CONVERSIONBASEDUNITS[unit_type]
        conversionbasedunit = IfcConversionBasedUnit.new(@ifc_model)
        dimensions = IfcDimensionalExponents.new(@ifc_model)
        dimensions.lengthexponent = BimTools::IfcManager::IfcInteger.new(@ifc_model, unit_values[4][0])
        dimensions.massexponent = BimTools::IfcManager::IfcInteger.new(@ifc_model, unit_values[4][1])
        dimensions.timeexponent = BimTools::IfcManager::IfcInteger.new(@ifc_model, unit_values[4][2])
        dimensions.electriccurrentexponent = BimTools::IfcManager::IfcInteger.new(@ifc_model, unit_values[4][3])
        dimensions.thermodynamictemperatureexponent = BimTools::IfcManager::IfcInteger.new(@ifc_model,
                                                                                           unit_values[4][4])
        dimensions.amountofsubstanceexponent = BimTools::IfcManager::IfcInteger.new(@ifc_model, unit_values[4][5])
        dimensions.luminousintensityexponent = BimTools::IfcManager::IfcInteger.new(@ifc_model, unit_values[4][6])
        conversionbasedunit.dimensions = dimensions
        conversionbasedunit.unittype = unit_values[1]
        conversionbasedunit.name = BimTools::IfcManager::IfcLabel.new(@ifc_model, unit_values[2])
        measurewithunit = IfcMeasureWithUnit.new(@ifc_model)
        conversionbasedunit.conversionfactor = measurewithunit
        unit = IfcSIUnit.new(@ifc_model)
        case unit_values[1]
        when :lengthunit
          valuecomponent = BimTools::IfcManager::IfcLengthMeasure.new(@ifc_model, unit_values[3])
        when :areaunit
          valuecomponent = BimTools::IfcManager::IfcAreaMeasure.new(@ifc_model, unit_values[3])
        when :volumeunit
          valuecomponent = BimTools::IfcManager::IfcVolumeMeasure.new(@ifc_model, unit_values[3])
        end
        valuecomponent.long = true
        measurewithunit.valuecomponent = valuecomponent
        measurewithunit.unitcomponent = unit
        measured_unit_values = IFC_UNITS[unit_values[0]]
        unit.dimensions = '*'
        unit.unittype = measured_unit_values[0]
        unit.prefix = measured_unit_values[1]
        unit.name = measured_unit_values[2]
        conversionbasedunit
      end
    end
  end
end
