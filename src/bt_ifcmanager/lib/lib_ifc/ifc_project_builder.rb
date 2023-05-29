# frozen_string_literal: true

#  ifc_project_builder.rb
#
#  Copyright 2023 Jan Brouwer <jan@brewsky.nl>
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

require_relative 'ifc_types'
require_relative 'PropertyReader'

module BimTools
  module IfcManager
    class IfcProjectBuilder
      attr_reader :ifc_project

      # Build IfcProject
      #
      # @param [IfcModel]
      # @param [IfcProject] ifc_entity OPTIONAL existing IFC entity to modify
      def self.build(ifc_model, ifc_entity = nil)
        builder = new(ifc_model, ifc_entity)
        yield(builder)
        builder.validate

        # add export summary for IfcProducts
        ifc_model.summary_add('IfcProject')

        builder.ifc_project
      end

      # Construct the builder object itself
      #
      # @param [IfcModel]
      # @param [IfcProject | nil] ifc_entity OPTIONAL existing IFC entity to modify
      def initialize(ifc_model, ifc_entity = nil)
        @ifc = Settings.ifc_module
        @ifc_model = ifc_model

        if ifc_entity
          if ifc_entity.class != @ifc::IfcProject
            raise ArgumentError, "Must be of type #{@ifc::IfcProject}, got #{ifc_entity.class}"
          end

          @ifc_project = ifc_entity
        else
          @ifc_project = @ifc::IfcProject.new(ifc_model, ifc_model.su_model) # @todo su_model needed parameter?
        end
        # Set project units to sketchup units
        @ifc_project.unitsincontext = @ifc::IfcUnitAssignment.new(ifc_model)
      end

      def validate
        set_global_id unless @ifc_project.globalid
        set_name unless @ifc_project.name
      end

      # Set the IfcProject GUID
      #
      # @param [String] name
      def set_global_id(_global_id = nil)
        @ifc_project.globalid = IfcManager::IfcGloballyUniqueId.new(@ifc_model, 'IfcProject')
      end

      # Set the IfcProject name
      #
      # @param [String] name
      def set_name(name = 'default project')
        @ifc_project.name = Types::IfcLabel.new(@ifc_model, name) if name
      end

      # Set the IfcProject description
      #
      # @param [String] description
      def set_description(description = nil)
        @ifc_project.description = Types::IfcLabel.new(@ifc_model, description) if description
      end

      # Set the IfcProject representationcontexts
      #
      # @param [IfcGeometricRepresentationContext[]] representationcontexts
      def set_representationcontexts(representationcontexts = [])
        @ifc_project.representationcontexts = Types::Set.new(representationcontexts) if representationcontexts
      end

      # get attributes from su object and add them to IfcProduct
      #
      # @param [SketchupComponentInstance] su_object
      def set_attributes_from_su_instance(su_instance)
        su_definition = su_instance.definition
        if dicts = su_definition.attribute_dictionaries
          dict_reader = BimTools::IfcManager::IfcDictionaryReader.new(@ifc_model, @ifc_project, dicts)
          dict_reader.set_attributes
          dict_reader.add_propertysets
          dict_reader.add_sketchup_definition_properties(@ifc_model, @ifc_project, su_definition)
          dict_reader.add_classifications
          dict_reader.add_sketchup_instance_properties(@ifc_model, @ifc_project, su_instance)
        end
      end
    end
  end
end
