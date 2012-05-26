class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.string :name, :limit => 100, :null => false
      t.integer :cluster_id
      t.integer :active 
      t.text    :config
      t.timestamps
    end
    create_table :rules do |t|
    	t.string :name
    	t.string :value
    	t.timestamps
    end
  end

  def self.down
    drop_table :settings
    drop_table :rules
  end
end