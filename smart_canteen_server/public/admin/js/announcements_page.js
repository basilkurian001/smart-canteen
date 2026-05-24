// js/announcements_page.js

document.addEventListener("DOMContentLoaded", () => {

  const token = localStorage.getItem("adminToken");
  if (!token) {
    location.href = "login.html";
    return;
  }

  const titleInput = document.getElementById("annTitle");
  const subtitleInput = document.getElementById("annSubtitle");
  const activeCheckbox = document.getElementById("annActive");

  let currentOfferId = null;

  /* =========================
     LOAD CURRENT ANNOUNCEMENT
  ========================= */
  async function loadAnnouncement() {
    try {
      const res = await fetch("/offers", {
        headers: { "Cache-Control": "no-cache" },
      });

      const data = await res.json();
      if (!data.offer) return;

      const offer = data.offer;
      currentOfferId = offer.id;

      titleInput.value = offer.title || "";
      subtitleInput.value = offer.subtitle || "";
      activeCheckbox.checked = !!offer.active;


    } catch (err) {
      console.error("Failed to load announcement", err);
    }
  }

  /* =========================
     SAVE (REPLACE OLD)
  ========================= */
  window.saveAnnouncement = async function () {
    const title = titleInput.value.trim();
    if (!title) {
      alert("Title is required");
      return;
    }

    try {
      await fetch("/offers", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: "Bearer " + token,
        },
        body: JSON.stringify({
          title,
          subtitle: subtitleInput.value.trim() || null,
          active: activeCheckbox.checked ? 1 : 0,
        }),
      });

      alert("Announcement updated successfully");
      loadAnnouncement();

    } catch (err) {
      console.error("Failed to save announcement", err);
      alert("Failed to save announcement");
    }
  };

  /* =========================
     INIT
  ========================= */
  loadAnnouncement();
});
