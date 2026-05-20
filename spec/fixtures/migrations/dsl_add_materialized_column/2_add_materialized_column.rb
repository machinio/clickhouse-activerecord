# frozen_string_literal: true

class AddMaterializedColumn < ActiveRecord::Migration[7.1]
  def up
    add_column :some, :value_doubled, :big_integer,
      null: false,
      materialized: 'value * 2'
  end
end
