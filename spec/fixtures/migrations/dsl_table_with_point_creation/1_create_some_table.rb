# frozen_string_literal: true

class CreateSomeTable < ActiveRecord::Migration[7.1]
  def up
    create_table :some, id: false do |t|
      t.point :point, null: false
    end
  end
end
