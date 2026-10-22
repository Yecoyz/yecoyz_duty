import { useState } from "react";
import { LogIn, LogOut } from "lucide-react";
import { useVisibility } from "../contexts/VisibilityContext";
import { useTranslation } from "../contexts/TranslationProvider";
import { callback } from "../utilites/callback";
import { formatClock } from "../lib/format";
import useNow from "../lib/useNow";
import { Avatar, Badge, Button, StatusDot } from "./ui";

const Profile = () => {
  const { t } = useTranslation();
  const { characterData, setDutyState, setShiftsData } = useVisibility();
  const { name, job, grade, isOnDuty, dutyStarted } = characterData;
  const [busy, setBusy] = useState(false);
  const now = useNow(isOnDuty);

  const elapsed = isOnDuty && dutyStarted ? now - dutyStarted : 0;

  const handleDutyToggle = () => {
    if (busy) return;
    setBusy(true);
    callback("toggleDuty")
      .then((res) => {
        if (!res || !res.success) return;
        setDutyState(res.isOnDuty, res.dutyStarted);
        if (Array.isArray(res.shifts)) setShiftsData(res.shifts);
      })
      .catch(() => {})
      .finally(() => setBusy(false));
  };

  return (
    <section className="profile">
      <div className="profile-row">
        <Avatar large online={isOnDuty} />
        <div className="profile-info">
          <h2 className="title">{name}</h2>
          <div className="meta-row">
            <span className="label">{job}</span>
            {grade && <Badge>{grade}</Badge>}
          </div>
        </div>
        <div className="duty-clock">
          <span className="label">
            <StatusDot on={isOnDuty} />
            {isOnDuty ? t("ui_proflieOnDuty") : t("ui_proflieOffDuty")}
          </span>
          <span className={`time${isOnDuty ? "" : " idle"}`}>{formatClock(elapsed)}</span>
        </div>
      </div>

      <Button variant={isOnDuty ? "ghost" : "primary"} block onClick={handleDutyToggle} disabled={busy}>
        {isOnDuty ? <LogOut size={15} /> : <LogIn size={15} />}
        {isOnDuty ? t("ui_proflieGoOffDuty") : t("ui_proflieGoOnDuty")}
      </Button>
    </section>
  );
};

export default Profile;
