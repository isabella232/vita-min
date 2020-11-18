require "rails_helper"

describe Ability do
  let(:subject) { Ability.new(user) }

  context "a nil user" do
    let(:user) { nil }
    let(:vita_partner) { create :vita_partner }
    let(:client) { create(:client, vita_partner: vita_partner) }
    let(:intake) { create(:intake, vita_partner: vita_partner, client: client) }

    it "cannot manage any client data" do
      expect(subject.can?(:administer, Client)).to eq false
      expect(subject.can?(:administer, IncomingTextMessage.new(client: client))).to eq false
      expect(subject.can?(:administer, OutgoingTextMessage.new(client: client))).to eq false
      expect(subject.can?(:administer, OutgoingEmail.new(client: client))).to eq false
      expect(subject.can?(:administer, IncomingEmail.new(client: client))).to eq false
      expect(subject.can?(:administer, User.new(vita_partner: vita_partner))).to eq false
      expect(subject.can?(:administer, Note.new(client: client))).to eq false
      expect(subject.can?(:administer, VitaPartner.new)).to eq false
      expect(subject.can?(:administer, SystemNote.new)).to eq false
    end
  end

  context "a user and client without an organization" do
    let(:user) { create(:user_with_org, vita_partner: nil) }
    let(:client) { create(:client, vita_partner: nil) }
    let(:intake) { create(:intake, vita_partner: nil, client: client) }

    it "cannot manage any client data" do
      expect(subject.can?(:administer, client)).to eq false
      expect(subject.can?(:administer, IncomingTextMessage.new(client: client))).to eq false
      expect(subject.can?(:administer, OutgoingTextMessage.new(client: client))).to eq false
      expect(subject.can?(:administer, OutgoingEmail.new(client: client))).to eq false
      expect(subject.can?(:administer, IncomingEmail.new(client: client))).to eq false
      expect(subject.can?(:administer, User.new(vita_partner: nil))).to eq false
      expect(subject.can?(:administer, Note.new(client: client))).to eq false
      expect(subject.can?(:administer, VitaPartner.new)).to eq false
      expect(subject.can?(:administer, SystemNote.new)).to eq false
    end
  end

  context "a user who is a member of a parent organization" do
    let(:child_org) { create :vita_partner }
    let(:parent_org) { create :vita_partner, sub_organizations: [child_org] }
    let(:user) { create :user_with_org, vita_partner: parent_org }
    let(:intake) { create(:intake, vita_partner: child_org, client: (create :client, vita_partner: child_org)) }
    let(:client) { intake.client }

    it "can manage data in child organizations" do
      expect(subject.can?(:administer, client)).to eq true
      expect(subject.can?(:administer, IncomingTextMessage.new(client: client))).to eq true
      expect(subject.can?(:administer, OutgoingTextMessage.new(client: client))).to eq true
      expect(subject.can?(:administer, OutgoingEmail.new(client: client))).to eq true
      expect(subject.can?(:administer, IncomingEmail.new(client: client))).to eq true
      expect(subject.can?(:administer, User.new(vita_partner: child_org))).to eq true
      expect(subject.can?(:administer, Note.new(client: client))).to eq true
      expect(subject.can?(:administer, child_org)).to eq true
      expect(subject.can?(:administer, VitaPartner.new)).to eq false
      expect(subject.can?(:administer, SystemNote.new(client: client))).to eq true
    end
  end

  context "a user who is a member of an organization without child organizations" do
    let(:user) { create :user_with_org, vita_partner: create(:vita_partner) }
    let(:accessible_client) { create(:client, vita_partner: user.vita_partner) }
    let(:accessible_intake) { create(:intake, vita_partner: user.vita_partner) }
    let(:other_vita_partner_client) { create(:client, vita_partner: create(:vita_partner)) }
    let(:nil_vita_partner_client) { create(:client, vita_partner: nil) }

    it "can manage data from their own organization" do
      expect(subject.can?(:administer, accessible_client)).to eq true
      expect(subject.can?(:administer, IncomingTextMessage.new(client: accessible_client))).to eq true
      expect(subject.can?(:administer, OutgoingTextMessage.new(client: accessible_client))).to eq true
      expect(subject.can?(:administer, OutgoingEmail.new(client: accessible_client))).to eq true
      expect(subject.can?(:administer, IncomingEmail.new(client: accessible_client))).to eq true
      expect(subject.can?(:administer, Document.new(client: accessible_client))).to eq true
      expect(subject.can?(:administer, User.new(vita_partner: user.vita_partner))).to eq true
      expect(subject.can?(:administer, Note.new(client: accessible_client))).to eq true
      expect(subject.can?(:administer, SystemNote.new(client: accessible_client))).to eq true
      expect(subject.can?(:administer, user.vita_partner)).to eq true
    end

    it "cannot manage data which lack an organization" do
      expect(subject.can?(:administer, nil_vita_partner_client)).to eq false
      expect(subject.can?(:administer, IncomingTextMessage.new(client: nil_vita_partner_client))).to eq false
      expect(subject.can?(:administer, OutgoingTextMessage.new(client: nil_vita_partner_client))).to eq false
      expect(subject.can?(:administer, OutgoingEmail.new(client: nil_vita_partner_client))).to eq false
      expect(subject.can?(:administer, IncomingEmail.new(client: nil_vita_partner_client))).to eq false
      expect(subject.can?(:administer, Document.new(client: nil_vita_partner_client))).to eq false
      expect(subject.can?(:administer, User.new(vita_partner: nil))).to eq false
      expect(subject.can?(:administer, Note.new(client: nil_vita_partner_client))).to eq false
      expect(subject.can?(:administer, SystemNote.new(client: nil_vita_partner_client))).to eq false
    end

    it "cannot manage data from another organization" do
      expect(subject.can?(:administer, other_vita_partner_client)).to eq false
      expect(subject.can?(:administer, IncomingTextMessage.new(client: other_vita_partner_client))).to eq false
      expect(subject.can?(:administer, OutgoingTextMessage.new(client: other_vita_partner_client))).to eq false
      expect(subject.can?(:administer, OutgoingEmail.new(client: other_vita_partner_client))).to eq false
      expect(subject.can?(:administer, IncomingEmail.new(client: other_vita_partner_client))).to eq false
      expect(subject.can?(:administer, Document.new(client: other_vita_partner_client))).to eq false
      expect(subject.can?(:administer, User.new(vita_partner: other_vita_partner_client.vita_partner))).to eq false
      expect(subject.can?(:administer, Note.new(client: other_vita_partner_client))).to eq false
      expect(subject.can?(:administer, SystemNote.new(client: other_vita_partner_client))).to eq false
      expect(subject.can?(:administer, other_vita_partner_client.vita_partner)).to eq false
    end
  end

  context "a coalition lead" do
    let(:coalition_member_organization) { create(:vita_partner) }
    let(:intake) { create(:intake, vita_partner: coalition_member_organization) }
    let(:user) { create :user_with_org, vita_partner: create(:vita_partner), supported_organizations: [coalition_member_organization] }
    let(:coalition_member_client) { create(:client, intake: intake, vita_partner: coalition_member_organization) }

    it "can manage data from the coalition member organization" do
      expect(subject.can?(:administer, coalition_member_client)).to eq true
      expect(subject.can?(:administer, IncomingTextMessage.new(client: coalition_member_client))).to eq true
      expect(subject.can?(:administer, OutgoingTextMessage.new(client: coalition_member_client))).to eq true
      expect(subject.can?(:administer, OutgoingEmail.new(client: coalition_member_client))).to eq true
      expect(subject.can?(:administer, IncomingEmail.new(client: coalition_member_client))).to eq true
      expect(subject.can?(:administer, Document.new(client: coalition_member_client))).to eq true
      expect(subject.can?(:administer, User.new(vita_partner: coalition_member_client.vita_partner))).to eq true
      expect(subject.can?(:administer, Note.new(client: coalition_member_client))).to eq true
      expect(subject.can?(:administer, SystemNote.new(client: coalition_member_client))).to eq true
    end
  end

  context "as an admin" do
    let(:user) { create(:user, is_admin: true) }
    let(:client) { create(:client, vita_partner: create(:vita_partner)) }

    it "can manage any data" do
      expect(subject.can?(:administer, client)).to eq true
      expect(subject.can?(:administer, IncomingTextMessage.new(client: client))).to eq true
      expect(subject.can?(:administer, OutgoingTextMessage.new(client: client))).to eq true
      expect(subject.can?(:administer, OutgoingEmail.new(client: client))).to eq true
      expect(subject.can?(:administer, IncomingEmail.new(client: client))).to eq true
      expect(subject.can?(:administer, Document.new(client: client))).to eq true
      expect(subject.can?(:administer, User.new)).to eq true
      expect(subject.can?(:administer, Note.new(client: client))).to eq true
      expect(subject.can?(:administer, VitaPartner.new)).to eq true
      expect(subject.can?(:administer, SystemNote.new)).to eq true
    end
  end
end
