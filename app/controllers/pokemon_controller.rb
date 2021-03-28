require 'csv'
require 'json'
require 'will_paginate/array'

class PokemonController < ApplicationController

  before_action :read_pokemon_list
  before_action :params_required, only: [:create]
  before_action :get_pokemon, only: [:update, :show, :destroy]

  @@filename = 'tmp/pokemon.csv'

  def index
    json_response(@pokemons.values.paginate(page: params[:page], per_page: 20))
  end

  def create
    new_pokemon = attrs
    @pokemons[new_pokemon['Name']] = new_pokemon

    save_pokemon_list

    json_response("Pokemon #{new_pokemon['Name']} created")
  end

  def update
    @pokemons[@pokemon['Name']] = @pokemon.merge(attrs)

    save_pokemon_list

    json_response("Pokemon #{@pokemon['Name']} updated")
  end

  def show
    json_response(@pokemon)
  end

  def destroy
    @pokemons.delete(@pokemon['Name'])

    save_pokemon_list

    json_response("Pokemon #{@pokemon['Name']} destroy")
  end

  def read_pokemon_list
    @pokemons = {}
    convert = {'#' => 'Num'}
    CSV.foreach(@@filename, headers: true, header_converters: lambda { |name| convert[name] || name }) do |row|
      @pokemons[row['Name']] = row.to_hash
    end
  end

  def save_pokemon_list
    values = @pokemons.values.sort{|a, b| a['Num'].to_i <=> b['Num'].to_i}
    CSV.open(@@filename, 'w', write_headers: true, headers: ['#'] + @pokemons.values[0].keys[1..-1]) do |writer|
      values.each do |pokemon|
        writer << pokemon.values
      end
    end
  end

  def params_required
    required_keys = [
      "Num",
      "Name",
      "Type 1",
      "Total",
      "HP",
      "Attack",
      "Defense",
      "Sp. Atk",
      "Sp. Def",
      "Speed",
      "Generation",
      "Legendary"
    ]

    required_keys.each do |key|
      unless params.has_key? key
        return json_response("Required params missing!!! \nPlease specifie those params #{required_keys.join(', ')}" , :bad_request)
      end
    end
  end

  def attrs
    params.permit("Num", "Name", "Type 1", "Type 2", "Total", "HP", "Attack", "Defense", "Sp. Atk", "Sp. Def", "Speed", "Generation", "Legendary")
  end

  def get_pokemon
    unless params['Name']
      json_response('Name must be specified', :not_found)
    end

    @pokemon = @pokemons[params['Name']]
  end

  def json_response(object, status = :ok)
    render json: object, status: status
  end

end
