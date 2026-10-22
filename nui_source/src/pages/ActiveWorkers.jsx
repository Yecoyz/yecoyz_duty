import { Users } from "lucide-react";
import WorkerRow from "../components/WorkerRow";
import { EmptyState } from "../components/ui";
import { useVisibility } from "../contexts/VisibilityContext";
import { useTranslation } from "../contexts/TranslationProvider";
import useNow from "../lib/useNow";

function ActiveWorkers() {
  const { workerData } = useVisibility();
  const { t } = useTranslation();
  const now = useNow();

  const online = workerData.filter((worker) => worker.online);
  const offline = workerData.filter((worker) => !worker.online);

  return (
    <div className="page">
      <div className="page-head">
        <h3 className="title">{t("ui_workersList")}</h3>
        <span className="label num">
          {online.length} / {workerData.length} {t("ui_online")}
        </span>
      </div>

      {workerData.length === 0 ? (
        <EmptyState icon={Users} text={t("ui_NoWorkersAvalibale")} />
      ) : (
        <div className="scroll">
          {[
            [t("ui_onlineWorkers"), online],
            [t("ui_offlineWorkers"), offline],
          ].map(
            ([label, workers]) =>
              workers.length > 0 && (
                <div key={label} className="group">
                  <div className="label">
                    <span>{label}</span>
                    <span className="num">{workers.length}</span>
                  </div>
                  <div className="list">
                    {workers.map((worker) => (
                      <WorkerRow key={worker.identifier} worker={worker} now={now} />
                    ))}
                  </div>
                </div>
              )
          )}
        </div>
      )}
    </div>
  );
}

export default ActiveWorkers;
