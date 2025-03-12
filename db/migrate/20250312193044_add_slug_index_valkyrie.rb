class AddSlugIndexValkyrie < ActiveRecord::Migration[6.1]
  def change
    add_index :orm_resources,
      "(metadata -> 'slug' ->> 0)",
      name: 'index_on_slug',
      where: "metadata -> 'slug' IS NOT NULL"
  end
end
