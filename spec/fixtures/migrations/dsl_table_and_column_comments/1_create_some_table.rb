# frozen_string_literal: true

class CreateSomeTable < ActiveRecord::Migration[7.1]
  def up
    create_table :some,
      options: 'MergeTree PARTITION BY toYYYYMM(date) ORDER BY (date)',
      comment: 'Stores some rows' do |t|
      t.date :date, null: false, comment: 'Event date'
      t.integer :value, null: false
    end
  end
end
