import { useCallback, useEffect, useState } from "react";
import { ClipboardList, Lock } from "lucide-react";
import Profile from "./components/Profile";
import TabSelector from "./components/TabSelector";
import { EmptyState, Stat } from "./components/ui";
import { VisibilityProvider, useVisibility } from "./contexts/VisibilityContext";
import { TranslationProvider, useTranslation } from "./contexts/TranslationProvider";
import { callback } from "./utilites/callback";
import { filterShifts, formatDuration, shiftStats } from "./lib/format";

// The duty menu as a yecoyz_tablet app: the same pages as /duty, laid out for the 1280 x 766 tablet screen.
const tablet = typeof window !== "undefined" ? window.Tablet : undefined;

const WeekStats = () => {
  const { t } = useTranslation();
  const { shiftsData, characterData } = useVisibility();
  // Only this job's shifts, plus old shifts saved before multijob support.
  const ownJob = shiftsData.filter((shift) => !shift.job || shift.job === characterData.jobName);
  const today = shiftStats(filterShifts(ownJob, { period: "day" }));
  const week = shiftStats(filterShifts(ownJob, { period: "week" }));

  return (
    <section className="tablet-stats">
      <span className="label">{t("ui_statistics")}</span>
      <div className="stats">
        <Stat label={t("ui_filterDay")} value={formatDuration(today.total)} />
        <Stat label={t("ui_filterWeek")} value={formatDuration(week.total)} accent />
        <Stat label={t("ui_totalShifts")} value={week.count} />
      </div>
    </section>
  );
};

const TabletContent = () => {
  const { t } = useTranslation();
  const { applyDutyData, characterData } = useVisibility();
  // loading, allowed or denied (the player's job is not in Config.Jobs)
  const [status, setStatus] = useState("loading");

  const load = useCallback(() => {
    callback("getDutyData")
      .then((data) => {
        if (!data || !data.allowed) return setStatus("denied");
        applyDutyData(data);
        setStatus("allowed");
      })
      .catch(() => setStatus("denied"));
    // applyDutyData only calls state setters.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!tablet) {
      load();
      return undefined;
    }

    const onVisibility = (visible) => {
      if (visible) load();
    };

    // Load when the app is opened and every time it is shown again, Lua asks for a refresh when duty
    // or the job changes somewhere else.
    tablet.ready(load);
    tablet.on("visibility", onVisibility);
    tablet.on("refresh", load);
    return () => {
      tablet.off("visibility", onVisibility);
      tablet.off("refresh", load);
    };
  }, [load]);

  return (
    <div className="tablet-app">
      <aside className="tablet-side">
        <header className="duty-header">
          <div className="duty-header-left">
            <div className="icon-tile">
              <ClipboardList size={18} />
            </div>
            <h1 className="title">{t("ui_DutyTitle")}</h1>
          </div>
        </header>

        {status === "allowed" && (
          <>
            <Profile />
            <WeekStats />
          </>
        )}
      </aside>

      <main className="tablet-main">
        {status === "allowed" && <TabSelector canManage={Boolean(characterData.isBoss)} />}
        {status === "loading" && <EmptyState icon={ClipboardList} text={t("ui_loading")} />}
        {status === "denied" && <EmptyState icon={Lock} text={t("ui_noAccess")} />}
      </main>
    </div>
  );
};

export default function TabletApp() {
  return (
    <VisibilityProvider alwaysVisible>
      <TranslationProvider>
        <TabletContent />
      </TranslationProvider>
    </VisibilityProvider>
  );
}
