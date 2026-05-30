"""initial schema

Revision ID: 001
Revises:
Create Date: 2026-05-30

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("username", sa.String(length=100), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_users_email"), "users", ["email"], unique=True)
    op.create_index(op.f("ix_users_id"), "users", ["id"], unique=False)
    op.create_index(op.f("ix_users_username"), "users", ["username"], unique=True)

    op.create_table(
        "plants",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("scientific_name", sa.String(length=200), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("care_tips", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_plants_id"), "plants", ["id"], unique=False)
    op.create_index(op.f("ix_plants_name"), "plants", ["name"], unique=True)

    op.create_table(
        "diseases",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("symptoms", sa.Text(), nullable=True),
        sa.Column("causes", sa.Text(), nullable=True),
        sa.Column("treatment", sa.Text(), nullable=True),
        sa.Column("prevention", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_diseases_id"), "diseases", ["id"], unique=False)
    op.create_index(op.f("ix_diseases_name"), "diseases", ["name"], unique=True)

    op.create_table(
        "detections",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("image_path", sa.String(length=512), nullable=False),
        sa.Column("plant_name", sa.String(length=100), nullable=True),
        sa.Column("disease_name", sa.String(length=200), nullable=True),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("result_json", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_detections_id"), "detections", ["id"], unique=False)
    op.create_index(op.f("ix_detections_user_id"), "detections", ["user_id"], unique=False)

    op.create_table(
        "favorites",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("item_type", sa.String(length=32), nullable=False),
        sa.Column("item_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_favorites_id"), "favorites", ["id"], unique=False)
    op.create_index(op.f("ix_favorites_user_id"), "favorites", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_table("favorites")
    op.drop_table("detections")
    op.drop_table("diseases")
    op.drop_table("plants")
    op.drop_table("users")
