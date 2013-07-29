class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :password_digest
      t.string :title
      t.string :mail
      t.integer :group_id
      t.boolean :admin

      t.timestamps
    end
  end
end