import { useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ClipboardList, X } from "lucide-react";
import Profile from "./components/Profile";
import TabSelector from "./components/TabSelector";
import { VisibilityProvider, useVisibility } from "./contexts/VisibilityContext";
import { TranslationProvider, useTranslation } from "./contexts/TranslationProvider";
import { callback } from "./utilites/callback";

const AppContent = () => {
  const { isVisible, setIsVisible, characterData } = useVisibility();
  const { t } = useTranslation();

  const handleClose = () => {
    setIsVisible(false);
    callback("closePage").catch(() => {});
  };

  useEffect(() => {
    if (!isVisible) return undefined;
    const onKey = (event) => {
      if (event.key === "Escape") handleClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });

  return (
    <AnimatePresence>
      {isVisible && (
        <div className="overlay">
          <motion.div
            className="panel duty"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 8 }}
            transition={{ duration: 0.2, ease: "easeOut" }}
          >
            <header className="duty-header">
              <div className="duty-header-left">
                <div className="icon-tile">
                  <ClipboardList size={18} />
                </div>
                <h1 className="title">{t("ui_DutyTitle")}</h1>
              </div>
              <button type="button" className="icon-button" onClick={handleClose} aria-label="Close">
                <X size={18} />
              </button>
            </header>

            <Profile />
            <TabSelector canManage={Boolean(characterData.isBoss)} />
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};

function App() {
  return (
    <VisibilityProvider>
      <TranslationProvider>
        <AppContent />
      </TranslationProvider>
    </VisibilityProvider>
  );
}

export default App;
