require "rails_helper"

RSpec.describe "a user viewing a client" do
  context "as an admin user" do
    let(:user) { create :admin_user }
    let(:client) { create :client, vita_partner: (create :vita_partner), intake: create(:intake, :with_contact_info) }
    let!(:other_vita_partner) { create :vita_partner, name: "Tax Help Test" }
    before { login_as user }

    scenario "can view and update client organization" do
      visit case_management_client_path(id: client.id)
      within ".client-header" do
        expect(page).to have_text client.vita_partner.name
        click_on "Edit"
      end
      expect(page.current_path).to eq edit_organization_case_management_client_path(id: client.id)
      expect(page).to have_text "Edit Organization for #{client.preferred_name}"
      select other_vita_partner.name, from: "Organization"
      click_on "Save"
      within ".client-header" do
        expect(page).to have_text other_vita_partner.name
      end
    end
  end

  context "user without admin access" do
    let!(:client) { create :client, vita_partner: (create :vita_partner), intake: create(:intake, :with_contact_info) }
    let!(:user) {
      create :user, memberships: [
        build(:membership, vita_partner_id: client.vita_partner_id),
        build(:membership)
      ]
    }

    before { login_as user }

    scenario "can view and cannot update organization" do
      visit case_management_client_path(id: client.id)
      within ".client-header__organization" do
        expect(page).to have_text client.vita_partner.display_name
        expect(page).not_to have_text "Edit"
      end
    end
  end

  context "user without admin access, but is coalition lead for client organization" do
    let(:user) { 
      create :user, memberships: [
      build(:membership, vita_partner: client.vita_partner, role: "lead"),
      build(:membership, vita_partner: create(:vita_partner, name: "Tax Helpers"), role: "lead")
    ] }
    let(:client) { create :client, vita_partner: (create :vita_partner), intake: create(:intake, :with_contact_info) }
    before { login_as user }

    scenario "can view and update client organization" do
      puts("memberships", user.memberships.inspect)

      visit case_management_client_path(id: client.id)
      within ".client-header" do
        expect(page).to have_text client.vita_partner.display_name
        click_on "Edit"
      end
      expect(page.current_path).to eq edit_organization_case_management_client_path(id: client.id)
      expect(page).to have_text "Edit Organization for #{client.preferred_name}"
      select "Tax Helpers", from: "Organization"
      click_on "Save"
      within ".client-header" do
        expect(page).to have_text "Tax Helpers"
      end
    end
  end

  context "user with only volunteer access to clients organization" do
    let(:user) { 
      create :user, memberships: [
      build(:membership, vita_partner: client.vita_partner),
    ] }
    let(:client) { create :client, vita_partner: (create :vita_partner), intake: create(:intake, :with_contact_info) }
    before { login_as user }

    scenario "can view and update client organization" do
      visit case_management_client_path(id: client.id)
      within ".client-header" do
        expect(page).to have_text client.vita_partner.display_name
        expect(page).not_to have_text "Edit"
      end
    end
  end
end