import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import TabletApp from "./TabletApp.jsx";

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <TabletApp />
  </StrictMode>
);
