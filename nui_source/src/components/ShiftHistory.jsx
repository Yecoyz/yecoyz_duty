import { useMemo, useState } from "react";
import { CalendarClock } from "lucide-react";
import { useTranslation } from "../contexts/TranslationProvider";
import {
  PERIODS,
  filterShifts,
  formatDay,
  formatDuration,
  formatTime,
  shiftEnd,
  shiftJobs,
  shiftStart,
  shiftStats,
} from "../lib/format";
import { Badge, EmptyState, Stat } from "./ui";

const periodLabel = {
  all: "ui_filterAll",
  day: "ui_filterDay",
  week: "ui_filterWeek",
  month: "ui_filterMonth",
};

// Stats and shift list with period filter. With `showJobs` the shifts can also be
// filtered per job (multijob), starting on `currentJob`.
const ShiftHistory = ({ shifts, showJobs = false, currentJob }) => {
  const { t } = useTranslation();
  const jobs = useMemo(() => (showJobs ? shiftJobs(shifts) : []), [shifts, showJobs]);
  const [period, setPeriod] = useState("all");
  const [job, setJob] = useState(() =>
    showJobs && shiftJobs(shifts).some((entry) => entry.name === currentJob) ? currentJob : "all"
  );

  const activeJob = job === "all" || jobs.some((entry) => entry.name === job) ? job : "all";
  const visible = useMemo(() => filterShifts(shifts, { period, job: activeJob }), [shifts, period, activeJob]);
  const stats = shiftStats(visible);
  const showJobBadge = showJobs && activeJob === "all" && jobs.length > 0;

  return (
    <>
      <div className="toolbar">
        {jobs.length > 1 && (
          <div className="chips">
            <button type="button" className={`chip${activeJob === "all" ? " active" : ""}`} onClick={() => setJob("all")}>
              {t("ui_allJobs")}
            </button>
            {jobs.map((entry) => (
              <button
                key={entry.name}
                type="button"
                className={`chip${activeJob === entry.name ? " active" : ""}`}
                onClick={() => setJob(entry.name)}
              >
                {entry.label}
              </button>
            ))}
          </div>
        )}
        <div className="segmented">
          {PERIODS.map((value) => (
            <button
              key={value}
              type="button"
              className={period === value ? "active" : ""}
              onClick={() => setPeriod(value)}
            >
              {t(periodLabel[value])}
            </button>
          ))}
        </div>
      </div>

      <div className="stats">
        <Stat label={t("ui_totalShifts")} value={stats.count} />
        <Stat label={t("ui_workingTime")} value={formatDuration(stats.total)} accent />
        <Stat label={t("ui_averageShift")} value={formatDuration(stats.average)} />
      </div>

      <div className="scroll">
        <div className="group">
          <div className="label">
            <span>{t("ui_shiftsHistory")}</span>
            <span className="num">
              {visible.length} {t("ui_shiftsCount")}
            </span>
          </div>
          {visible.length === 0 ? (
            <EmptyState icon={CalendarClock} text={t("ui_shiftsNoRecord")} />
          ) : (
            <div className="list">
              {visible.map((shift, index) => {
                const start = shiftStart(shift);
                const end = shiftEnd(shift);
                return (
                  <div key={`${shift.startTime || shift.startTimeFormatted}-${index}`} className="shift inset">
                    <div className="shift-date">
                      <span className="shift-day">{formatDay(start)}</span>
                      <span className="shift-range">
                        {formatTime(start)} – {formatTime(end)}
                      </span>
                    </div>
                    {showJobBadge && shift.job && <Badge>{shift.jobLabel || shift.job}</Badge>}
                    <span className="shift-duration">{formatDuration(shift.duration)}</span>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default ShiftHistory;
