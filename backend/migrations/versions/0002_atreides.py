"""atreides

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-03 16:40:57.328728
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import mysql

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:

    op.create_table(
        "atreides_batch",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("filename", sa.String(length=255), nullable=False),
        sa.Column("rows", sa.Integer(), nullable=False),
        sa.Column("accepted", sa.Integer(), nullable=False),
        sa.Column("dropped", sa.Integer(), nullable=False),
        sa.Column("tracks", sa.Integer(), nullable=False),
        sa.Column("first_at", mysql.DATETIME(fsp=6), nullable=True),
        sa.Column("last_at", mysql.DATETIME(fsp=6), nullable=True),
        sa.Column("shifted_s", sa.Integer(), nullable=False),
        sa.Column("received_via", sa.String(length=16), nullable=False),
        sa.Column("received_by", sa.String(length=64), nullable=True),
        sa.Column("created_at", mysql.DATETIME(fsp=6), server_default=sa.text("CURRENT_TIMESTAMP(6)"), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_atreides_batch")),
    )
    op.create_table(
        "atreides_detection",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("batch_id", sa.Integer(), nullable=False),
        sa.Column("track_id", sa.String(length=64), nullable=False),
        sa.Column("at", mysql.DATETIME(fsp=6), nullable=False),
        sa.Column("lat", sa.Double(), nullable=False),
        sa.Column("lon", sa.Double(), nullable=False),
        sa.Column("role", sa.String(length=16), nullable=False),
        sa.Column("primary_role", sa.String(length=16), nullable=True),
        sa.Column("primary_confidence", sa.String(length=8), nullable=True),
        sa.Column("primary_reasoning", sa.String(length=255), nullable=True),
        sa.Column("primary_route_points", sa.Integer(), nullable=True),
        sa.Column("primary_route_span_km", sa.Double(), nullable=True),
        sa.Column("source_role", sa.String(length=16), nullable=True),
        sa.Column("source_confidence", sa.String(length=8), nullable=True),
        sa.Column("source_reasoning", sa.String(length=255), nullable=True),
        sa.Column("source_route_points", sa.Integer(), nullable=True),
        sa.Column("source_route_span_km", sa.Double(), nullable=True),
        sa.Column("content_type", sa.String(length=16), nullable=True),
        sa.Column("file_len", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(
            ["batch_id"],
            ["atreides_batch.id"],
            name=op.f("fk_atreides_detection_batch_id_atreides_batch"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_atreides_detection")),
    )
    op.create_index(op.f("ix_atreides_detection_at"), "atreides_detection", ["at"], unique=False)
    op.create_index(op.f("ix_atreides_detection_batch_id"), "atreides_detection", ["batch_id"], unique=False)
    op.create_index("ix_atreides_detection_lat_lon", "atreides_detection", ["lat", "lon"], unique=False)
    op.create_index(op.f("ix_atreides_detection_track_id"), "atreides_detection", ["track_id"], unique=False)


def downgrade() -> None:
    op.drop_table("atreides_detection")
    op.drop_table("atreides_batch")
