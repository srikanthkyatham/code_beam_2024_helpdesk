defmodule Helpdesk.Repo.Migrations.MigrateResources1 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:users, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :text, null: false
      add :org_id, :bigint
    end

    create table(:tokens, primary_key: false) do
      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :jti, :text, null: false, primary_key: true
      add :subject, :text, null: false
      add :expires_at, :utc_datetime, null: false
      add :purpose, :text, null: false
      add :extra_data, :map

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create table(:tickets, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :subject, :text, null: false
      add :status, :text, null: false, default: "open"
      add :attachments, {:array, :map}, default: []
      add :representative_id, :uuid
      add :org_id, :bigint
    end

    create table(:representatives, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
    end

    alter table(:tickets) do
      modify :representative_id,
             references(:representatives,
               column: :id,
               name: "tickets_representative_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    alter table(:representatives) do
      add :name, :text, null: false
    end

    create table(:orgs_membership, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :role, :text, null: false, default: "member"

      add :user_id,
          references(:users,
            column: :id,
            name: "orgs_membership_user_id_fkey",
            type: :uuid,
            prefix: "public"
          )

      add :org_id, :bigint
    end

    create table(:org, primary_key: false) do
      add :id, :bigserial, null: false, primary_key: true
    end

    alter table(:users) do
      modify :org_id,
             references(:org,
               column: :id,
               name: "users_org_id_fkey",
               type: :bigint,
               prefix: "public"
             )
    end

    create unique_index(:users, [:email], name: "users_unique_email_index")

    alter table(:tickets) do
      modify :org_id,
             references(:org,
               column: :id,
               name: "tickets_org_id_fkey",
               type: :bigint,
               prefix: "public"
             )
    end

    alter table(:orgs_membership) do
      modify :org_id,
             references(:org,
               column: :id,
               name: "orgs_membership_org_id_fkey",
               type: :bigint,
               prefix: "public"
             )
    end

    alter table(:org) do
      add :name, :text
      add :slug, :text
    end
  end

  def down do
    alter table(:org) do
      remove :slug
      remove :name
    end

    drop constraint(:orgs_membership, "orgs_membership_org_id_fkey")

    alter table(:orgs_membership) do
      modify :org_id, :bigint
    end

    drop constraint(:tickets, "tickets_org_id_fkey")

    alter table(:tickets) do
      modify :org_id, :bigint
    end

    drop_if_exists unique_index(:users, [:email], name: "users_unique_email_index")

    drop constraint(:users, "users_org_id_fkey")

    alter table(:users) do
      modify :org_id, :bigint
    end

    drop table(:org)

    drop constraint(:orgs_membership, "orgs_membership_user_id_fkey")

    drop table(:orgs_membership)

    alter table(:representatives) do
      remove :name
    end

    drop constraint(:tickets, "tickets_representative_id_fkey")

    alter table(:tickets) do
      modify :representative_id, :uuid
    end

    drop table(:representatives)

    drop table(:tickets)

    drop table(:tokens)

    drop table(:users)
  end
end
