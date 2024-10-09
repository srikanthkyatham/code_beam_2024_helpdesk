defmodule Helpdesk.Checks.ActorIsAdmin do
  use Ash.Policy.SimpleCheck

  # This is used when logging a breakdown of how a policy is applied - see Logging below.
  def describe(_) do
    "actor is admin"
  end

  # The context here may have a changeset, query, resource, and domain module, depending
  # on the action being run.
  # `match?` should return true or false, and answer the statement being posed in the description,
  # i.e "is the actor old enough?"
  def match?(%Helpdesk.Accounts.User{id: id} = _actor, _context, _opts) do
    dbg()

    Helpdesk.Orgs.membership_of_user!(id)
    |> is_admin?()
  end

  def match?(actor, context, opts) do
    dbg()

    false
  end

  def is_admin?(membership) do
    dbg()
    membership.role == :admin
  end
end
