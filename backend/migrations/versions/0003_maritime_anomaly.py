"""maritime anomaly

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-03 20:40:31.697459
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import mysql

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "anomaly_evaluation",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("created_at", mysql.DATETIME(fsp=6), server_default=sa.text("CURRENT_TIMESTAMP(6)"), nullable=False),
        sa.Column("source_id", sa.String(length=64), nullable=False),
        sa.Column("tracks", sa.Integer(), nullable=False),
        sa.Column("anomalous", sa.Integer(), nullable=False),
        sa.Column("results", sa.JSON(), nullable=False),
        sa.Column("settings", sa.JSON(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_anomaly_evaluation")),
    )
    op.create_table(
        "anomaly_label",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("source_id", sa.String(length=64), nullable=False),
        sa.Column("track_id", sa.String(length=64), nullable=False),
        sa.Column("kind", sa.String(length=16), nullable=False),
        sa.Column("start_at", mysql.DATETIME(fsp=6), nullable=True),
        sa.Column("end_at", mysql.DATETIME(fsp=6), nullable=True),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_anomaly_label")),
    )
    op.create_index(op.f("ix_anomaly_label_track_id"), "anomaly_label", ["track_id"], unique=False)
    op.create_table(
        "anomaly_setting",
        sa.Column("key", sa.String(length=48), nullable=False),
        sa.Column("value", sa.Double(), nullable=False),
        sa.Column("updated_by", sa.String(length=64), nullable=True),
        sa.Column("updated_at", mysql.DATETIME(fsp=6), server_default=sa.text("CURRENT_TIMESTAMP(6)"), nullable=False),
        sa.PrimaryKeyConstraint("key", name=op.f("pk_anomaly_setting")),
    )
    op.create_table(
        "track_alert",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("source_id", sa.String(length=64), nullable=False),
        sa.Column("source_kind", sa.String(length=8), nullable=False),
        sa.Column("track_id", sa.String(length=64), nullable=False),
        sa.Column("kinds", sa.JSON(), nullable=False),
        sa.Column("method", sa.String(length=8), nullable=False),
        sa.Column("score", sa.SmallInteger(), nullable=False),
        sa.Column("rule_score", sa.SmallInteger(), nullable=False),
        sa.Column("stat_score", sa.Double(), nullable=True),
        sa.Column("confidence", sa.Double(), nullable=False),
        sa.Column("reasons", sa.JSON(), nullable=False),
        sa.Column("uncertainty", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("first_at", mysql.DATETIME(fsp=6), nullable=False),
        sa.Column("last_at", mysql.DATETIME(fsp=6), nullable=False),
        sa.Column("lat", sa.Double(), nullable=False),
        sa.Column("lon", sa.Double(), nullable=False),
        sa.Column("zone_ids", sa.JSON(), nullable=False),
        sa.Column("case_id", sa.Uuid(), nullable=True),
        sa.Column("suppress_until", mysql.DATETIME(fsp=6), nullable=True),
        sa.Column("updated_by", sa.String(length=64), nullable=True),
        sa.Column("created_at", mysql.DATETIME(fsp=6), server_default=sa.text("CURRENT_TIMESTAMP(6)"), nullable=False),
        sa.Column("updated_at", mysql.DATETIME(fsp=6), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_track_alert")),
    )
    op.create_index(op.f("ix_track_alert_last_at"), "track_alert", ["last_at"], unique=False)
    op.create_index(op.f("ix_track_alert_status"), "track_alert", ["status"], unique=False)
    op.create_index("ix_track_alert_track", "track_alert", ["source_id", "track_id"], unique=False)
    op.create_table(
        "track_alert_event",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("alert_id", sa.BigInteger(), nullable=False),
        sa.Column("at", mysql.DATETIME(fsp=6), nullable=False),
        sa.Column("actor", sa.String(length=64), nullable=True),
        sa.Column("action", sa.String(length=24), nullable=False),
        sa.Column("detail", sa.JSON(), nullable=False),
        sa.ForeignKeyConstraint(
            ["alert_id"], ["track_alert.id"], name=op.f("fk_track_alert_event_alert_id_track_alert"), ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_track_alert_event")),
    )
    op.create_index(op.f("ix_track_alert_event_alert_id"), "track_alert_event", ["alert_id"], unique=False)


def downgrade() -> None:
    for t in ("track_alert_event", "track_alert", "anomaly_setting", "anomaly_label", "anomaly_evaluation"):
        op.drop_table(t)
