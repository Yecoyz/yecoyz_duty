import { createContext, useContext, useState, useEffect } from "react";
import { isBrowser, mockData } from "../lib/mock";

const VisibilityContext = createContext();

export const useVisibility = () => useContext(VisibilityContext);

const toList = (value) => (Array.isArray(value) ? value : []);

const defaultHistoryManagement = { edit: false, remove: false, maxHours: 24 };

export const VisibilityProvider = ({ children }) => {
  const [isVisible, setIsVisible] = useState(isBrowser);
  const [workerData, setWorkerData] = useState(isBrowser ? mockData.workers : []);
  const [shiftsData, setShiftsData] = useState(isBrowser ? mockData.shifts : []);
  // What the boss may change in a worker's history (Config.HistoryManagement).
  const [historyManagement, setHistoryManagement] = useState(
    isBrowser ? mockData.historyManagement : defaultHistoryManagement
  );
  const [characterData, setCharacterData] = useState(
    isBrowser
      ? mockData.character
      : { name: "", job: "", jobName: "", grade: "", isOnDuty: false, dutyStarted: null, isBoss: false }
  );

  // dutyStarted is always epoch seconds (or null).
  const setDutyState = (isOnDuty, dutyStarted) => {
    setCharacterData((prev) => ({
      ...prev,
      isOnDuty: Boolean(isOnDuty),
      dutyStarted: isOnDuty ? dutyStarted || Math.floor(Date.now() / 1000) : null,
    }));
  };

  useEffect(() => {
    const handleMessage = (event) => {
      const data = event.data;
      if (!data) return;

      if (data.action === "showUI") {
        setHistoryManagement({ ...defaultHistoryManagement, ...data.historyManagement });
        setWorkerData(toList(data.workers));
        setShiftsData(toList(data.shifts));
        if (data.character) {
          setCharacterData({
            ...data.character,
            isOnDuty: Boolean(data.character.isOnDuty),
            dutyStarted: data.character.dutyStarted || null,
            isBoss: Boolean(data.character.isBoss),
          });
        }
        setIsVisible(true);
      } else if (data.action === "hideUI") {
        setIsVisible(false);
      } else if (data.action === "updateWorkers") {
        setWorkerData(toList(data.workers));
      } else if (data.action === "updateShifts") {
        setShiftsData(toList(data.shifts));
      } else if (data.action === "updateCharacter" && data.character) {
        setCharacterData((prev) => ({ ...prev, ...data.character }));
      }
    };

    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  return (
    <VisibilityContext.Provider
      value={{
        isVisible,
        setIsVisible,
        workerData,
        shiftsData,
        characterData,
        historyManagement,
        setDutyState,
        setWorkerData,
        setShiftsData,
        setCharacterData,
      }}
    >
      {children}
    </VisibilityContext.Provider>
  );
};
