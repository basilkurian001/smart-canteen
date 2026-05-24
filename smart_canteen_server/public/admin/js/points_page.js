const pointsInput = document.getElementById("pointsPerRupee");
const discountInput = document.getElementById("maxDiscountPercent");

/* =========================
   LOAD SETTINGS
========================= */
async function loadSettings() {
  const res = await fetch("/admin/points", {
    headers: {
      Authorization: "Bearer " + token
    }
  });

  const data = await res.json();

  if (data.success) {
    pointsInput.value = data.settings.pointsPerRupee;
    discountInput.value = data.settings.maxDiscountPercent;
  }
}

/* =========================
   SAVE SETTINGS
========================= */
async function saveSettings() {
  const pointsPerRupee = parseFloat(pointsInput.value);
  const maxDiscountPercent = parseInt(discountInput.value);

  if (pointsPerRupee <= 0 || maxDiscountPercent < 0 || maxDiscountPercent > 100) {
    alert("Invalid values");
    return;
  }

  await fetch("/admin/points", {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer " + token
    },
    body: JSON.stringify({
      pointsPerRupee,
      maxDiscountPercent
    })
  });

  alert("Point settings updated successfully");
}

/* =========================
   INIT
========================= */
loadSettings();
