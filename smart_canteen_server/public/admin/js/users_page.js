const table = document.getElementById("usersTable");
let users = [];

/* =========================
   HELPERS
========================= */
function normalize(text) {
  return String(text).toLowerCase().replace(/\s+/g, "");
}

function resolveAvatar(img) {
  if (!img) return "/uploads/avatars/default_avatar.png";

  // ✅ Google / external avatar
  if (img.startsWith("http://") || img.startsWith("https://")) {
    return img;
  }

  // ✅ Already absolute local path
  if (img.startsWith("/")) {
    return img;
  }

  // ✅ Local uploaded avatar filename
  return `/uploads/avatars/${img}`;
}

/* =========================
   LOAD USERS
========================= */
async function loadUsers() {
  try {
    const res = await fetch("/admin/users", {
      headers: {
        Authorization: "Bearer " + token
      }
    });

    const data = await res.json();
    users = data.users || [];
    renderUsers(users);
  } catch (err) {
    console.error("Failed to load users", err);
  }
}

/* =========================
   RENDER USERS
========================= */
function renderUsers(list) {
  table.innerHTML = "";

  list.forEach(u => {
    const tr = document.createElement("tr");

    tr.dataset.search = normalize(
      `${u.id} ${u.username} ${u.email}`
    );

    tr.innerHTML = `
      <td>${u.id}</td>
      <td>
        <img
          src="${resolveAvatar(u.avatar)}"
          class="user-avatar"
          alt="avatar"
        />
      </td>
      <td>${u.name}</td>
      <td>${u.email}</td>
      <td>${u.points}</td>
    `;

    table.appendChild(tr);
  });
}

/* =========================
   SMART SEARCH
========================= */
function filterUsers() {
  const q = normalize(
    document.getElementById("userSearch").value
  );

  document.querySelectorAll("#usersTable tr").forEach(row => {
    row.style.display = row.dataset.search.includes(q)
      ? ""
      : "none";
  });
}

/* =========================
   INIT
========================= */
loadUsers();
