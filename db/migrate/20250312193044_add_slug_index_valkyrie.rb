class AddSlugIndexValkyrie < ActiveRecord::Migration[6.1]
  def change
    # add index to orm_resources table for json field metadata subfield slug first element if the first element is not null
    add_index :orm_resources, "(metadata->'slug'->>0)",
      name: "index_orm_resources_on_metadata_slug_0",
      where: "metadata -> 'slug' IS NOT NULL"

  end
end
