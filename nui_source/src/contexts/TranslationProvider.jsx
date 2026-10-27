import { createContext, useContext, useState, useEffect } from "react";
import { useVisibility } from "./VisibilityContext";
import { callback } from "../utilites/callback";

const TranslationContext = createContext();

export const useTranslation = () => useContext(TranslationContext);

// Used when a key is missing from the locale file (and when running in a browser).
const fallback = {
  ui_DutyTitle: "Duty Manager",
  ui_workersList: "Workers",
  ui_online: "Online",
  ui_offline: "Offline",
  ui_onlineWorkers: "Online",
  ui_offlineWorkers: "Offline",
  ui_noWorkersFound: "No workers found",
  ui_backToWorkers: "Back",
  ui_NoWorkersAvalibale: "No workers available",
  ui_WorkersWillAppearWhenAdded: "Workers will appear here when added",
  ui_history: "History",
  ui_statistics: "Statistics",
  ui_totalShifts: "Shifts",
  ui_workingTime: "Worked",
  ui_averageShift: "Average",
  ui_profileGrade: "Grade",
  ui_proflieOnDuty: "On duty",
  ui_proflieOffDuty: "Off duty",
  ui_proflieGoOnDuty: "Go on duty",
  ui_proflieGoOffDuty: "Go off duty",
  ui_tabWorkers: "Workers",
  ui_tabHistory: "History",
  ui_tabManageWorkers: "Manage",
  ui_shiftsHistory: "Shifts",
  ui_shiftsNoRecord: "No shifts recorded yet",
  ui_manageWorkers: "Manage Workers",
  ui_searchWorkers: "Search workers...",
  ui_allJobs: "All jobs",
  ui_filterAll: "All",
  ui_filterDay: "Today",
  ui_filterWeek: "Week",
  ui_filterMonth: "Month",
  ui_shiftsCount: "shifts",
  ui_jobOnlyNote: "Only shifts worked in your job are shown",
  ui_editShift: "Edit",
  ui_removeShift: "Remove",
  ui_removeShiftConfirm: "Remove this shift?",
  ui_save: "Save",
  ui_cancel: "Cancel",
  ui_hours: "Hours",
  ui_minutes: "Minutes",
  ui_shiftEdited: "Edited",
  ui_shiftEditedBy: "Edited by",
};

export const TranslationProvider = ({ children }) => {
  const { isVisible } = useVisibility();
  const [localTranslations, setLocalTranslations] = useState({});

  useEffect(() => {
    if (!isVisible) return;
    callback("getLocale")
      .then((translations) => {
        if (translations) setLocalTranslations(translations);
      })
      .catch(() => {});
  }, [isVisible]);

  const t = (key) => localTranslations[key] || fallback[key] || key;

  return <TranslationContext.Provider value={{ t }}>{children}</TranslationContext.Provider>;
};
