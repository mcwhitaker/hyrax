RSpec.describe 'records/edit_fields/_subject.html.erb', type: :view do
  let(:work) { GenericWork.new }
  let(:form) { Sufia::Forms::WorkForm.new(work, nil) }
  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "records/edit_fields/subject", f: f, key: 'subject' %>
      <% end %>
    )
  end

  before do
    assign(:form, form)
    render inline: form_template
  end

  it 'has url for autocomplete service' do
    expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/generic_works/subject"][data-autocomplete="subject"]')
  end
end
