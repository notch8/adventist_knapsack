# frozen_string_literal: true

mappings = {}

## Set custom bulkrax parser field mappings for app
mappings["Bulkrax::OaiAdventistQdcParser"] = {
  'abstract' => { from:  ['abstract'] },
  'aark_id' => { from:  ['aark_id'] },
  'identifier' => { from:  ['identifier'], source_identifier: true },
  'bibliographic_citation' => { from:  ['bibliographic_citation'] },
  'creator' => { from:  ['creator'] },
  'contributor' => { from:  ['contributor'] },
  'edition' => { from:  ['edition'] },
  'resource_type' => { from:  ['resource_type'] },
  'issue_number' => { from:  ['issue_number'] },
  'language' => { from:  ['language'] },
  'description' => { from:  ['description'] },
  'pagination' => { from:  ['pagination'] },
  'extent' => { from:  ['extent'], split: ';' },
  'source' => { from:  ['source'] },
  'date_issued' => { from:  ['date_issued'] },
  'alt' => { from:  ['geocode'] },
  'publisher' => { from:  ['publisher'], split: ';' },
  'rights_statement' => { from:  ['rights_statement'] },
  'part_of' => { from:  ['part_of'] },
  'part' => { from:  ['part_of'] },
  'date_created' => { from:  ['date_created'] },
  'title' => { from:  ['title'] },
  'subject' => { from:  ['subject'], split: ';' },
  'volume_number' => { from:  ['volume_number'] },
  'keyword' => { from: ['keyword'], split: ';' },
  'location' => { from: ['location'], split: ';' },
  'model' => { from: ['model', 'work_type'] },
  'remote_files' => { from: ['related_url'], split: ';', parsed: true },
  'thumbnail_url' => { from: ['thumbnail_url'], default_thumbnail: true, parsed: true },
  'video_embed' => { from: ['video_embed'] },
  'refereed' => { from: ['peer_reviewed'] }
}
mappings["Bulkrax::CsvParser"] = {
  'abstract' => { from:  ['description.abstract'] },
  'aark_id' => { from:  ['identifier.ark'] },
  'identifier' => { from:  ['identifier'], source_identifier: true },
  'bibliographic_citation' => { from:  ['identifier.bibliographicCitation'] },
  'creator' => { from:  ['creator'], split: ';' },
  'contributor' => { from:  ['contributor'], split: ';' },
  'edition' => { from:  ['title.release'] },
  'resource_type' => { from:  ['type'] },
  'issue_number' => { from:  ['relation.isPartOfIssue'] },
  'language' => { from:  ['language'], split: ';' },
  'description' => { from:  ['description'], split: ';' },
  'pagination' => { from:  ['format.extent'] },
  'extent' => { from:  ['format.extent'], split: ';' },
  'source' => { from:  ['source'], split: ';' },
  'date_issued' => { from:  ['date'] },
  'alt' => { from:  ['coverage.spatial'] },
  'publisher' => { from:  ['publisher'], split: ';' },
  'rights_statement' => { from:  ['rights'] },
  'part_of' => { from:  ['relation.isPartOf'], split: ';' },
  'part' => { from:  ['relation.isPartOf'] },
  'date_created' => { from:  ['date.other'] },
  'title' => { from:  ['title'] },
  'subject' => { from:  ['subject'], split: ';' },
  'volume_number' => { from:  ['relation.isPartOfVolume'] },
  'keyword' => { from: ['keyword'], split: ';' },
  'location' => { from: ['location'], split: ';' },
  'model' => { from: ['work_type'] },
  'remote_files' => { from: ['related_url'], split: ';', parsed: true },
  'remote_url' => { from: ['official_url', 'remote_url'], split: ';' },
  'thumbnail_url' => { from: ['thumbnail_url'], default_thumbnail: true, parsed: true },
  'video_embed' => { from: ['video_embed'] },
  'refereed' => { from: ['peer_reviewed'] },
  'parents' => { from: ['parents'], split: /\s*[;|]\s*/, related_parents_field_mapping: true },
  'children' => { from: ['children'], split: /\s*[;|]\s*/, related_children_field_mapping: true }
}

Hyku.default_bulkrax_field_mappings = mappings
