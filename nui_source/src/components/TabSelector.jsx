import { useState } from "react";
import { Clock, ShieldCheck, Users } from "lucide-react";
import ActiveWorkers from "../pages/ActiveWorkers";
import History from "../pages/History";
import ManageWorkers from "../pages/ManageWorkers";
import { useTranslation } from "../contexts/TranslationProvider";

const TabSelector = ({ canManage }) => {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState("activeworkers");

  const tabs = [
    { id: "activeworkers", icon: Users, label: t("ui_tabWorkers") },
    { id: "history", icon: Clock, label: t("ui_tabHistory") },
    canManage && { id: "manageworkers", icon: ShieldCheck, label: t("ui_tabManageWorkers") },
  ].filter(Boolean);

  const current = tabs.some((tab) => tab.id === activeTab) ? activeTab : "activeworkers";

  return (
    <>
      <nav className="tabs">
        {tabs.map(({ id, icon: Icon, label }) => (
          <button key={id} type="button" className={`tab${current === id ? " active" : ""}`} onClick={() => setActiveTab(id)}>
            <Icon size={15} />
            {label}
          </button>
        ))}
      </nav>

      {current === "activeworkers" && <ActiveWorkers />}
      {current === "history" && <History />}
      {current === "manageworkers" && <ManageWorkers />}
    </>
  );
};

export default TabSelector;
