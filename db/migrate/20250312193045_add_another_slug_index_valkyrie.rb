class AddAnotherSlugIndexValkyrie < ActiveRecord::Migration[6.1]
  def change
    add_index :orm_resources,
      "((metadata -> 'slug'))",
      using: :gin,
      name: 'idx_metadata_slug',
      where: "metadata -> 'slug' IS NOT NULL"
  end
end
