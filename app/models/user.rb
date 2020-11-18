# == Schema Information
#
# Table name: users
#
#  id                        :bigint           not null, primary key
#  active                    :boolean
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string
#  email                     :string           not null
#  encrypted_access_token    :string
#  encrypted_access_token_iv :string
#  encrypted_password        :string           default(""), not null
#  failed_attempts           :integer          default(0), not null
#  invitation_accepted_at    :datetime
#  invitation_created_at     :datetime
#  invitation_limit          :integer
#  invitation_sent_at        :datetime
#  invitation_token          :string
#  invitations_count         :integer          default(0)
#  is_admin                  :boolean          default(FALSE), not null
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string
#  locked_at                 :datetime
#  name                      :string
#  provider                  :string
#  reset_password_sent_at    :datetime
#  reset_password_token      :string
#  role                      :string
#  sign_in_count             :integer          default(0), not null
#  suspended                 :boolean
#  ticket_restriction        :string
#  timezone                  :string           default("America/New_York"), not null
#  two_factor_auth_enabled   :boolean
#  uid                       :string
#  verified                  :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  invited_by_id             :bigint
#  vita_partner_id           :bigint
#  zendesk_user_id           :bigint
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invitations_count     (invitations_count)
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_vita_partner_id       (vita_partner_id)
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (vita_partner_id => vita_partners.id)
#
class User < ApplicationRecord
  devise :database_authenticatable, :lockable, :validatable, :timeoutable, :trackable, :invitable, :recoverable

  has_many :assigned_tax_returns, class_name: "TaxReturn", foreign_key: :assigned_user_id

  #
  belongs_to :vita_partner, optional: true
  has_and_belongs_to_many :supported_organizations,
           join_table: "users_vita_partners",
           class_name: "VitaPartner"
  #

  has_many :memberships
  accepts_nested_attributes_for :memberships

  attr_encrypted :access_token, key: ->(_) { EnvironmentCredentials.dig(:db_encryption_key) }

  validates_presence_of :name
  validates_inclusion_of :timezone, in: ActiveSupport::TimeZone.country_zones("us").map { |tz| tz.tzinfo.name }

  # returns true if the user has role "lead" for organization or its parents.
  # @param keyword [Boolean] exclude_ancestors
  def can_lead?(vita_partner, exclude_ancestors: false)
    memberships.where({
        role: "lead",
        vita_partner_id: [
          vita_partner.id,
          *(vita_partner.ancestors unless exclude_ancestors)
        ].compact
    }).exists?
  end

  # returns organizations a user is a member of, and their children (if any).
  def accessible_organizations
    member_org_ids = memberships.pluck(:vita_partner_id)
    VitaPartner.where(id: member_org_ids).or(
      VitaPartner.where(parent_organization_id: member_org_ids)
    )
  end
end

