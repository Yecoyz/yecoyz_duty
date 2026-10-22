import ShiftHistory from "../components/ShiftHistory";
import { useVisibility } from "../contexts/VisibilityContext";
import { useTranslation } from "../contexts/TranslationProvider";

function History() {
  const { shiftsData, characterData } = useVisibility();
  const { t } = useTranslation();

  return (
    <div className="page">
      <div className="page-head">
        <h3 className="title">{t("ui_history")}</h3>
        <span className="label">{t("ui_statistics")}</span>
      </div>
      <ShiftHistory shifts={shiftsData} showJobs currentJob={characterData.jobName} />
    </div>
  );
}

export default History;
