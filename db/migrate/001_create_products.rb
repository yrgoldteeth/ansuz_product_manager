class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.string :name
      t.float :price
      t.integer :category_id
      t.string :description
      t.boolean :active, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end
