import { useState } from "react";
import { Pencil, Trash2 } from "lucide-react";
import { useTranslation } from "../contexts/TranslationProvider";
import { formatDay, formatDuration, formatTime, shiftEnd, shiftStart } from "../lib/format";
import { Badge, Button } from "./ui";

// One shift. With `manage` (boss in the Manage tab) the shift can be edited or removed.
const ShiftRow = ({ shift, showJobBadge, manage }) => {
  const { t } = useTranslation();
  const [mode, setMode] = useState(null); // null | "edit" | "remove"
  const [busy, setBusy] = useState(false);
  const total = Math.max(0, Math.floor(Number(shift.duration) || 0));
  const [hours, setHours] = useState(Math.floor(total / 3600));
  const [minutes, setMinutes] = useState(Math.floor((total % 3600) / 60));

  const start = shiftStart(shift);
  const end = shiftEnd(shift);
  const canEdit = Boolean(manage?.edit && shift.editable);
  const canRemove = Boolean(manage?.remove && shift.editable);
  const maxHours = manage?.maxHours || 24;
  const duration = (Number(hours) || 0) * 3600 + (Number(minutes) || 0) * 60;
  const validDuration = duration >= 60 && duration <= maxHours * 3600;

  const run = (action) => {
    if (busy) return;
    setBusy(true);
    action()
      .then((ok) => ok && setMode(null))
      .finally(() => setBusy(false));
  };

  const openEdit = () => {
    setHours(Math.floor(total / 3600));
    setMinutes(Math.floor((total % 3600) / 60));
    setMode("edit");
  };

  const clamp = (value, max) => Math.min(max, Math.max(0, Math.floor(Number(value) || 0)));

  return (
    <div className={`shift-card inset${mode ? " active" : ""}`}>
      <div className="shift">
        <div className="shift-date">
          <span className="shift-day">{formatDay(start)}</span>
          <span className="shift-range">
            {formatTime(start)} – {formatTime(end)}
          </span>
        </div>
        {showJobBadge && shift.job && <Badge>{shift.jobLabel || shift.job}</Badge>}
        {shift.edited && <Badge tone="warn">{t("ui_shiftEdited")}</Badge>}
        <span className="shift-duration">{formatDuration(shift.duration)}</span>
        {(canEdit || canRemove) && !mode && (
          <div className="shift-actions">
            {canEdit && (
              <button type="button" className="icon-button sm" onClick={openEdit} aria-label={t("ui_editShift")}>
                <Pencil size={13} />
              </button>
            )}
            {canRemove && (
              <button
                type="button"
                className="icon-button sm danger"
                onClick={() => setMode("remove")}
                aria-label={t("ui_removeShift")}
              >
                <Trash2 size={13} />
              </button>
            )}
          </div>
        )}
      </div>

      {shift.edited && manage && (
        <div className="shift-note">
          {t("ui_shiftEditedBy")} {shift.edited.by || "?"} · {formatDuration(shift.edited.originalDuration)} →{" "}
          {formatDuration(shift.duration)}
        </div>
      )}

      {mode === "edit" && (
        <div className="shift-editor">
          <label className="field">
            <span className="label">{t("ui_hours")}</span>
            <input
              type="number"
              min={0}
              max={maxHours}
              value={hours}
              onChange={(e) => setHours(clamp(e.target.value, maxHours))}
            />
          </label>
          <label className="field">
            <span className="label">{t("ui_minutes")}</span>
            <input
              type="number"
              min={0}
              max={59}
              value={minutes}
              onChange={(e) => setMinutes(clamp(e.target.value, 59))}
            />
          </label>
          <div className="shift-editor-buttons">
            <Button variant="ghost" size="sm" onClick={() => setMode(null)} disabled={busy}>
              {t("ui_cancel")}
            </Button>
            <Button
              size="sm"
              onClick={() => run(() => manage.onEdit(shift, duration))}
              disabled={busy || !validDuration || duration === total}
            >
              {t("ui_save")}
            </Button>
          </div>
        </div>
      )}

      {mode === "remove" && (
        <div className="shift-editor">
          <span className="shift-confirm">{t("ui_removeShiftConfirm")}</span>
          <div className="shift-editor-buttons">
            <Button variant="ghost" size="sm" onClick={() => setMode(null)} disabled={busy}>
              {t("ui_cancel")}
            </Button>
            <Button variant="danger" size="sm" onClick={() => run(() => manage.onRemove(shift))} disabled={busy}>
              {t("ui_removeShift")}
            </Button>
          </div>
        </div>
      )}
    </div>
  );
};

export default ShiftRow;
