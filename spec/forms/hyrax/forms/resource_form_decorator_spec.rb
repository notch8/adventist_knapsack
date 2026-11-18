# frozen_string_literal: true

RSpec.describe Hyrax::Forms::ResourceForm, '.for' do
  let(:resource) { JournalArticleResource.new }

  it 'accepts the admin_set_id: keyword Bulkrax passes' do
    form = described_class.for(resource:, admin_set_id: 'admin_set/default')

    expect(form).to be_a(JournalArticleResourceForm)
    expect(form.model).to eq(resource)
  end

  it 'still builds the form without admin_set_id:' do
    expect(described_class.for(resource:)).to be_a(JournalArticleResourceForm)
  end
end
