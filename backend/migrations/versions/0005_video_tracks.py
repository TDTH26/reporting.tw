"""video tracks

Revision ID: 0005
Revises: 0004
Create Date: 2026-10-03 21:43:55.496713
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import mysql

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "video_track",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("feed_id", sa.String(length=64), nullable=False),
        sa.Column("key", sa.String(length=80), nullable=False),
        sa.Column("status", sa.String(length=8), nullable=False),
        sa.Column("craft_domain", sa.String(length=16), nullable=False),
        sa.Column("craft_type", sa.String(length=32), nullable=True),
        sa.Column("first_at", mysql.DATETIME(fsp=6), nullable=False),
        sa.Column("last_at", mysql.DATETIME(fsp=6), nullable=False),
        sa.Column("hits", sa.Integer(), nullable=False),
        sa.Column("path", sa.JSON(), nullable=False),
        sa.Column("behaviours", sa.JSON(), nullable=False),
        sa.ForeignKeyConstraint(["feed_id"], ["video_feed.id"], name=op.f("fk_video_track_feed_id_video_feed")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_video_track")),
        sa.UniqueConstraint("key", name=op.f("uq_video_track_key")),
    )
    op.create_index("ix_video_track_feed_status", "video_track", ["feed_id", "status"], unique=False)
    op.create_index(op.f("ix_video_track_last_at"), "video_track", ["last_at"], unique=False)
    op.add_column("ai_job", sa.Column("frame_at", mysql.DATETIME(fsp=6), nullable=True))
    op.add_column("video_feed", sa.Column("alert_zone", sa.JSON(), nullable=True))


def downgrade() -> None:
    op.drop_table("video_track")
    op.drop_column("video_feed", "alert_zone")
    op.drop_column("ai_job", "frame_at")
