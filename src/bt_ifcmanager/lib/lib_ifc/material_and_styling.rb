# frozen_string_literal: true

#  material_and_styling.rb
#
#  Copyright 2022 Jan Brouwer <jan@brewsky.nl>
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

module BimTools
  module IfcManager
    # Class that manages the relationship between a Sketchup material and
    #  it's IFC counterparts (material and styling)
    #
    # @param [IfcModel] ifc_model
    # @param [Sketchup::Material] su_material Sketckup material for which IFC material and styles will be created
    class MaterialAndStyling
      attr_reader :image_texture

      def initialize(ifc_model, su_material = nil)
        @ifc_model = ifc_model
        @ifc = Settings.ifc_module
        @su_material = su_material
        @image_texture = create_image_texture(su_material)
        @surface_styles_both = nil
        @surface_styles_positive = nil
        @surface_styles_negative = nil
      end

      # Creates IfcRelAssociatesMaterial
      #
      # @param [Sketchup::Material] su_material
      # @return [IfcRelAssociatesMaterial] Material association
      def create_material_assoc(su_material=nil)
        material_name = if su_material
                          su_material.display_name
                        else
                          'Default'
                        end
        persistent_id = if su_material
                          su_material.persistent_id
                        else
                          'IfcMaterial.Default'
                        end

        material_assoc = @ifc::IfcRelAssociatesMaterial.new(@ifc_model)
        material_assoc.globalid = IfcManager::IfcGloballyUniqueId.new(@ifc_model, persistent_id)
        material_assoc.relatingmaterial = @ifc::IfcMaterial.new(@ifc_model)
        material_assoc.relatingmaterial.name = Types::IfcLabel.new(@ifc_model, material_name)
        material_assoc.relatedobjects = Types::Set.new
        material_assoc
      end

      # Creates IfcRelAssociatesMaterial
      #
      # @param [Sketchup::Material] su_material
      # @return [Ifc_Set] Set of IFC surface styles
      def create_surface_styles(su_material, side=:both)
        if @ifc_model.options[:colors]
          if su_material
            name = su_material.name
            alpha = su_material.alpha
            color = su_material.color
          else
            name = 'Default'
            alpha = 1.0

            rendering_options = Sketchup.active_model.rendering_options
            if side == :negative
              color = rendering_options['FaceBackColor']
            else
              color = rendering_options['FaceFrontColor']
            end
          end

          red_ratio = color.red.to_f / 255
          green_ratio = color.green.to_f / 255
          blue_ratio = color.blue.to_f / 255
          alpha_ratio = 1 - alpha

          colourrgb = @ifc::IfcColourRgb.new(@ifc_model)
          colourrgb.red = Types::IfcNormalisedRatioMeasure.new(@ifc_model, red_ratio)
          colourrgb.green = Types::IfcNormalisedRatioMeasure.new(@ifc_model, green_ratio)
          colourrgb.blue = Types::IfcNormalisedRatioMeasure.new(@ifc_model, blue_ratio)

          # IFC2x3 IfcSurfaceStyleRendering
          # @todo IFC4 IfcSurfaceStyleShading (transparency change)
          if @ifc::IfcSurfaceStyleShading.respond_to?(:transparency)
            surface_style_rendering = @ifc::IfcSurfaceStyleShading.new(@ifc_model)
          else
            surface_style_rendering = @ifc::IfcSurfaceStyleRendering.new(@ifc_model)
            surface_style_rendering.reflectancemethod = :notdefined
          end
          surface_style_rendering.surfacecolour = colourrgb
          surface_style_rendering.transparency = Types::IfcNormalisedRatioMeasure.new(@ifc_model, alpha_ratio)

          surface_style = @ifc::IfcSurfaceStyle.new(@ifc_model)
          surface_style.side = side
          surface_style.name = Types::IfcLabel.new(@ifc_model, name)
          surface_style.styles = Types::Set.new([surface_style_rendering])

          if @image_texture
            texture_style = @ifc::IfcSurfaceStyleWithTextures.new(@ifc_model)
            texture_style.textures = IfcManager::Types::List.new([@image_texture])
            surface_style.styles.add(texture_style)
          end

          # Workaround for mandatory IfcPresentationStyleAssignment in IFC2x3
          if Settings.ifc_version == 'IFC 2x3'
            style_assignment = @ifc::IfcPresentationStyleAssignment.new(@ifc_model)
            style_assignment.styles = Types::Set.new([surface_style])
          else
            style_assignment = surface_style
          end

          style_assignment
        end
      end

      def create_image_texture(su_material)
        if @ifc_model.textures && su_material && su_texture = su_material.texture
          image_texture = @ifc::IfcImageTexture.new(@ifc_model)
          image_texture.repeats = true
          image_texture.repeatt = true
          texturetransform = @ifc::IfcCartesianTransformationOperator2DnonUniform.new(@ifc_model)
          texturetransform.axis1 = @ifc_model.default_axis
          texturetransform.axis2 = @ifc_model.default_refdirection
          texturetransform.localorigin = @ifc_model.default_location
          texturetransform.scale = Types::IfcReal.new(@ifc_model, Types::IfcLengthMeasure.new(@ifc_model,su_texture.width).convert)
          texturetransform.scale2 = Types::IfcReal.new(@ifc_model, Types::IfcLengthMeasure.new(@ifc_model,su_texture.height).convert)
          image_texture.texturetransform = texturetransform
          image_texture.urlreference = Types::IfcURIReference.new(@ifc_model, File.basename(su_texture.filename))
          image_texture
        end
      end

      # Add the material to an IFC entity
      #
      # @param[IfcProduct] ifc_entity IFC Entity
      def add_to_material(ifc_entity)
        @material_assoc ||= create_material_assoc(@su_material)
        @material_assoc.relatedobjects.add(ifc_entity)
      end

      # Add the stylings to a shaperepresentation
      #
      # @param [IfcRepresentationItem] representation_item
      def get_styling(side=nil)
        case side
        when :positive
          @surface_styles_positive ||= create_surface_styles(@su_material, side)
          return @surface_styles_positive
        when :negative
          @surface_styles_negative ||= create_surface_styles(@su_material, side)
          return @surface_styles_negative
        else # :both
          @surface_styles_both ||= create_surface_styles(@su_material, :both)
          return @surface_styles_both
        end
      end
    end
  end
end
