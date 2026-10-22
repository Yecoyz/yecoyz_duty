import { useState } from "react";
import { ChevronLeft, Search, Users } from "lucide-react";
import ShiftHistory from "../components/ShiftHistory";
import WorkerRow from "../components/WorkerRow";
import { Avatar, Badge, Button, EmptyState } from "../components/ui";
import { useVisibility } from "../contexts/VisibilityContext";
import { useTranslation } from "../contexts/TranslationProvider";
import { callback } from "../utilites/callback";

function ManageWorkers() {
  const { workerData, characterData } = useVisibility();
  const { t } = useTranslation();
  const [selected, setSelected] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");

  const handleSelectWorker = (worker) => {
    callback("getEmployeeHistory", worker.identifier)
      .then((shifts) => setSelected({ worker, shifts: Array.isArray(shifts) ? shifts : [] }))
      .catch(() => setSelected({ worker, shifts: [] }));
  };

  if (selected) {
    const { worker, shifts } = selected;
    return (
      <div className="page">
        <div className="page-head">
          <Button variant="ghost" size="sm" onClick={() => setSelected(null)}>
            <ChevronLeft size={14} />
            {t("ui_backToWorkers")}
          </Button>
          <span className="label">{characterData.job}</span>
        </div>

        <div className="detail-head inset">
          <Avatar online={Boolean(worker.online)} />
          <div className="profile-info">
            <span className="worker-name">{worker.name}</span>
            <div className="meta-row">
              {worker.grade && <Badge>{worker.grade}</Badge>}
              <span className="label">{worker.online ? t("ui_online") : t("ui_offline")}</span>
            </div>
          </div>
        </div>

        <ShiftHistory key={worker.identifier} shifts={shifts} />
      </div>
    );
  }

  const term = searchTerm.trim().toLowerCase();
  const filtered = workerData
    .filter((worker) => String(worker.name || "").toLowerCase().includes(term))
    .sort((a, b) => Number(Boolean(b.online)) - Number(Boolean(a.online)));

  return (
    <div className="page">
      <div className="page-head">
        <h3 className="title">{t("ui_manageWorkers")}</h3>
        <span className="label num">{workerData.length}</span>
      </div>

      <div className="search">
        <Search size={15} />
        <input
          type="text"
          placeholder={t("ui_searchWorkers")}
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      <div className="scroll">
        {filtered.length === 0 ? (
          <EmptyState icon={Users} text={t("ui_noWorkersFound")} />
        ) : (
          <div className="list">
            {filtered.map((worker) => (
              <WorkerRow key={worker.identifier} worker={worker} onClick={() => handleSelectWorker(worker)} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default ManageWorkers;
