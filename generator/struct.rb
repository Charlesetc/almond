# generator/struct.rb

require_relative '../data.rb'
require 'pry'

# TODO: Make function definitions as neat as this.
#       Standardize the api for pluggins.
module Structs

  def ingest_struct(tree)
    if tree.arguments.length != 1
      raise "struct takes one argument"
    end
    if not tree.block
      raise "struct takes a block"
    end
    if tree.block.arguments and tree.block.arguments.length != 0
      raise "struct's block does not take arguments"
    end

    tree.block.forest.each do |tree|
      unless tree.is_ident?
        raise "struct's block must be a list of idents"
      end
    end


    @struct_count ||= NUMBER_OF_TYPES
    @struct_count += 1
    @struct_definitions[tree.arguments[0].symbol] = [tree.block.forest.map { |t| t.symbol }, @struct_count]
  end

  def struct_headers
    inner_list = @struct_definitions.values.map do |symbols, i|
      "[]string{" + symbols.map { |x| '"' + x.to_s + '"' }.join(", ") + "}"
    end.join(", ")

    [
      "\nvar struct_definitions [][]string = [][]string{",
      inner_list,
      "}\n",
    ].join
  end

end
