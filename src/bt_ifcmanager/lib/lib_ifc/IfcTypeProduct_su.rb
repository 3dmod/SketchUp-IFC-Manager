#  IfcTypeProduct_su.rb
#
#  Copyright 2018 Jan Brouwer <jan@brewsky.nl>
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

require_relative 'set'
require_relative 'list'
require_relative('IfcGloballyUniqueId')
require_relative 'IfcLabel'

module BimTools
  module IfcTypeProduct_su
    include BimTools::IfcManager::Settings.ifc_module

    attr_accessor :su_object, :objecttypeof

    # @param sketchup [Sketchup::ComponentDefinition]
    def initialize(ifc_model, definition)
      @definition = definition
      super
      ifc_version = BimTools::IfcManager::Settings.ifc_version

      # Set PredefinedType to default value if it exists
      @predefinedtype = :notdefined if attributes.include? :PredefinedType

      # @objecttypeof = BimTools::IfcManager::Ifc_Set.new()
      rel_defines_by_type = IfcRelDefinesByType.new(@ifc_model)
      rel_defines_by_type.relatingtype = self
      rel_defines_by_type.relatedobjects = BimTools::IfcManager::Ifc_Set.new
      # @objecttypeof.add(rel_defines_by_type)
      @objecttypeof = rel_defines_by_type

      # (!) duplicate code with IfcProduct_su

      # also set "tag" to component instance name?
      # tag definition: The tag (or label) identifier at the particular instance of a product, e.g. the serial number, or the position number. It is the identifier at the occurrence level.

      if definition.attribute_dictionaries && definition.attribute_dictionaries[ifc_version] && props_ifc = definition.attribute_dictionaries[ifc_version].attribute_dictionaries
        props_ifc.each do |prop_dict|
          prop = prop_dict.name
          prop_sym = prop.to_sym
          if attributes.include? prop_sym

            property_reader = BimTools::PropertyReader.new(prop_dict)
            dict_value = property_reader.value
            value_type = property_reader.value_type
            attribute_type = property_reader.attribute_type

            if attribute_type == 'choice'
              # Skip this attribute, this is not a value but a reference
            elsif attribute_type == 'enumeration'
              send("#{prop.downcase}=", dict_value)
            else
              entity_type = false
              if value_type
                begin
                  entity_type = BimTools::IfcManager.const_get(value_type)
                  value_entity = entity_type.new(dict_value)
                rescue StandardError => e
                  puts "Error creating IfcTypeProduct property type: #{self.class}, #{e}"
                end
              end
              unless entity_type

                value_entity = case attribute_type
                               when 'boolean'
                                 BimTools::IfcManager::IfcBoolean.new(dict_value)
                               when 'double'
                                 BimTools::IfcManager::IfcReal.new(dict_value)
                               when 'long'
                                 BimTools::IfcManager::IfcInteger.new(dict_value)
                               else # "string" and others?
                                 BimTools::IfcManager::IfcLabel.new(dict_value)
                               end
              end
              send("#{prop.downcase}=", value_entity)
            end
          else
            # if prop_dict.attribute_dictionaries && prop_dict.name != "instanceAttributes"
            #   rel_defines_by_properties = IfcRelDefinesByProperties.new( ifc_model, prop_dict )
            #   rel_defines_by_properties.relatedobjects.add( self )
            # end
          end
        end
      end

      @name = BimTools::IfcManager::IfcLabel.new(definition.name)
      @globalid = BimTools::IfcManager::IfcGloballyUniqueId.new(definition)
      faces = definition.entities.select { |entity| entity.is_a?(Sketchup::Face) }
      create_representation(faces)
    end

    # Add representation to the IfcProduct, transform geometry with given transformation
    # @param [Sketchup::Transformation] transformation
    def create_representation(faces)
      definition = @definition

      # # set representation based on definition
      # unless @representation
      #   @representation = IfcProductDefinitionShape.new(@ifc_model, definition)
      # end

      # representation = @representation.representations.first

      # Check if Mapped representation should be used
      # if representation.representationtype.value == "MappedRepresentation"
      puts 'maprep'
      # mapped_item = IfcMappedItem.new( @ifc_model )
      mappingsource = IfcRepresentationMap.new(@ifc_model)
      self.representationmaps = BimTools::IfcManager::Ifc_List.new([mappingsource])
      mappingtarget = IfcCartesianTransformationOperator3D.new(@ifc_model)
      mappingtarget.localorigin = @ifc_model.default_location
      mappingsource.mappingorigin = @ifc_model.default_placement
      mappingsource.mappingorigin.location = @ifc_model.default_location
      mappingsource.mappingorigin.axis = @ifc_model.default_axis
      mappingsource.mappingorigin.refdirection = @ifc_model.default_refdirection

      # mapped_item.mappingsource = mappingsource
      # mapped_item.mappingtarget = mappingtarget

      mapped_representation = @ifc_model.mapped_representation?(definition)
      unless mapped_representation
        mapped_representation = IfcShapeRepresentation.new(@ifc_model, nil)
        brep = IfcFacetedBrep.new(@ifc_model, faces, Geom::Transformation.new(Geom::Point3d.new))
        mapped_representation.items.add(brep)
        @ifc_model.add_mapped_representation(definition, mapped_representation)
      end

      mappingsource.mappedrepresentation = mapped_representation
      # representation.items.add( mapped_item )
      # puts representation.step
      # else
      #   brep = IfcFacetedBrep.new( @ifc_model, faces, transformation )
      #   # representation.items.add( brep )
      # end

      # # add color from su-object material, or a su_parent's
      # if @ifc_model.options[:colors]
      #   IfcStyledItem.new( @ifc_model, brep, su_material )
      # end
    end

    def collect_psets(ifc_model, attr_dict)
      if attr_dict.is_a? Sketchup::AttributeDictionary && !(attr_dict.name == 'AppliedSchemaTypes' || ifc_model.su_model.classifications[attr_dict.name])
        reldef = IfcRelDefinesByProperties.new(ifc_model, attr_dict)
        reldef.relatedobjects.add(self)
        if attr_dict.attribute_dictionaries
          attr_dict.attribute_dictionaries.each do |sub_attr_dict|
            collect_psets(ifc_model, sub_attr_dict)
          end
        end
      end
    end

    # add classifications
    def collect_classifications(ifc_model, definition)
      su_model = ifc_model.su_model
      active_classifications = BimTools::IfcManager::Settings.classification_names

      # Collect all attached classifications except for IFC
      if definition.attribute_dictionaries
        definition.attribute_dictionaries.each do |attr_dict|
          next unless active_classifications.keys.include? attr_dict.name

          skc_reader = active_classifications[attr_dict.name]

          # Create classifications if they don't exist
          if ifc_model.classifications.keys.include?(attr_dict.name)
            ifc_classification = ifc_model.classifications[attr_dict.name]
          else
            ifc_classification = IfcClassification.new(ifc_model)
            ifc_model.classifications[attr_dict.name] = ifc_classification
            classification_properties = skc_reader.properties
            if classification_properties.key?('creator')
              ifc_classification.source = BimTools::IfcManager::IfcLabel.new(classification_properties.creator)
            end
            if classification_properties.key?('edition')
              ifc_classification.edition = BimTools::IfcManager::IfcLabel.new(classification_properties.edition)
            end
            # ifc_classification.editiondate
            ifc_classification.name = BimTools::IfcManager::IfcLabel.new(attr_dict.name)
          end

          attributes = []
          attr_dict.attribute_dictionaries.each do |attribute|
            attributes << attribute['value']
          end

          # No way to map values with certainty, just pick the first 2
          next unless attributes.length > 1

          ifc_classification_reference = ifc_classification.ifc_classification_references[attributes[0]]
          next if ifc_classification_reference

          ifc_classification_reference = IfcClassificationReference.new(ifc_model)
          # ifc_classification_reference.location = ""

          # Catch IFC4 changes
          if IfcClassificationReference.method_defined?(:itemreference)
            ifc_classification_reference.itemreference = BimTools::IfcManager::IfcIdentifier.new(attributes[0])
          else
            ifc_classification_reference.identification = BimTools::IfcManager::IfcIdentifier.new(attributes[0])
          end
          ifc_classification_reference.name = BimTools::IfcManager::IfcLabel.new(attributes[1])
          ifc_classification_reference.referencedsource = ifc_classification

          # add ifc_classification_reference to the list of references in the classification
          ifc_classification.ifc_classification_references[attributes[0]] = ifc_classification_reference

          # create IfcRelAssociatesClassification
          rel = IfcRelAssociatesClassification.new(ifc_model)
          rel.relatedobjects = BimTools::IfcManager::Ifc_Set.new([self])
          rel.relatingclassification = ifc_classification_reference
          ifc_classification_reference.ifc_rel_associates_classification = rel
        end
      end
    end
  end
end
