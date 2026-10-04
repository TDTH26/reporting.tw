"""case recommendations

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-03 21:10:25.629743
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import mysql

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "case_recommendation",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("case_id", sa.Uuid(), nullable=False),
        sa.Column("code", sa.String(length=80), nullable=False),
        sa.Column("kind", sa.String(length=24), nullable=False),
        sa.Column("priority", sa.SmallInteger(), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("detail", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("final_text", sa.Text(), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("decided_by", sa.String(length=64), nullable=True),
        sa.Column("decided_at", mysql.DATETIME(fsp=6), nullable=True),
        sa.Column("created_at", mysql.DATETIME(fsp=6), server_default=sa.text("CURRENT_TIMESTAMP(6)"), nullable=False),
        sa.ForeignKeyConstraint(["case_id"], ["cases.id"], name=op.f("fk_case_recommendation_case_id_cases")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_case_recommendation")),
        sa.UniqueConstraint("case_id", "code", name="uq_case_recommendation"),
    )
    op.create_index(op.f("ix_case_recommendation_case_id"), "case_recommendation", ["case_id"], unique=False)


def downgrade() -> None:
    op.drop_table("case_recommendation")
