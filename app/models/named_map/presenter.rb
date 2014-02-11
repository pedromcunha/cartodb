# encoding: utf-8

module CartoDB
  module NamedMapsWrapper
		class Presenter

      LAYER_TYPES_TO_DECORATE = [ 'torque' ]

			def initialize(visualization, options, configuration)
        @visualization  = visualization
        @options        = options
        @configuration	= configuration

        @named_map          = nil
        @named_map_template = nil
        @loaded				    = false
      end #initialize

      # Prepares additional data to decorate layers in the LAYER_TYPES_TO_DECORATE list
      def get_decoration_for_layer(layer_type, layer_index)
        return {} if not LAYER_TYPES_TO_DECORATE.include? layer_type

        load_named_map_data() if !@loaded

        params = {}
        @named_map_template[:placeholders].each { |key, value|
          params[key.to_s] = value[:default]
        }

        { 
          'named_map' =>  {
            'name' =>         @named_map_template[:name],
            'layer_index' =>  layer_index,
            'params' =>       params
          }
        }
      end #get_decoration_for_layer

      # Prepare a PORO (Hash object) for easy JSONification
      # @see https://github.com/CartoDB/cartodb.js/blob/privacy-maps/doc/vizjson_format.md
      def to_poro
      	load_named_map_data() if !@loaded

        layers = @visualization.layers(:cartodb)
        layers_data = Array.new

        layers.each { |layer|
          layer_vizjson = layer.get_presenter(@options, @configuration).to_vizjson_v2()
          data = {
            layer_name: layer_vizjson[:options][:layer_name],
            interactivity: layer_vizjson[:options][:interactivity]
          }

          if ( layer_vizjson.include?(:infowindow) && !layer_vizjson[:infowindow].nil?() && 
               layer_vizjson[:infowindow].fetch('fields').size > 0 )
            data[:infowindow] = layer_vizjson[:infowindow]
          end

          if ( layer_vizjson.include?(:legend) && !layer_vizjson[:legend].nil?() && 
               layer_vizjson[:legend].fetch('type') != "none" )
            data[:legend] = layer_vizjson[:legend]
          end

          layers_data.push(data)
        }

        params = {}
        @named_map_template[:placeholders].each { |key, value|
          params[key] = value[:default]
        }

        if (@visualization.layers(:cartodb).size() == 0)
          # When there no layer don't return anything
          nil
        else
          {
            type:     'namedmap',
            order:    1,
            options:  {
              type:               'namedmap',
              user_name:          @options.fetch(:user_name),
              tiler_protocol:     @configuration[:tiler]['public']['protocol'],
              tiler_domain:       @configuration[:tiler]['public']['domain'],
              tiler_port:         @configuration[:tiler]['public']['port'],
              cdn_url:            @configuration.fetch(:cdn_url, nil),
              named_map:          {
                name:     @named_map_template[:name],
                auth:     @named_map_template[:auth][:method],
                params:   params,
                layers:   layers_data
              }
            }
          }
        end
      end #to_poro

      private

      # Loads the data of a given named map
      def load_named_map_data()
      	named_maps = NamedMaps.new(
            {
              name:     @options.fetch(:user_name),
              api_key:  @options.fetch(:api_key)
            },
            {
              protocol:   @configuration[:tiler]['private']['protocol'],
              domain:     @configuration[:tiler]['private']['domain'],
              port:       @configuration[:tiler]['private']['port'],
              verifycert: (@configuration[:tiler]['private']['verifycert'] rescue true)
            }
          )
      	@named_map = named_maps.get(NamedMap.normalize_name(@visualization.id))
        @named_map_template = @named_map.template.fetch(:template) if not @named_map.nil?
      	@loaded = true
      end #fetch

		end #Presenter
	end #NamedMapsWrapper
end #CartoDB