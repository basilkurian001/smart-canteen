const table = document.getElementById("foodTable");

let foods = [];

/* =========================
   FUNCTIONS
========================= */
async function loadFoods() {
  const res = await fetch("/admin/foods", {
    headers: { Authorization: "Bearer " + token }
  });

  const data = await res.json();
  foods = data.foods || [];
  renderFoods();
}

function resolveImage(image) {
  if (!image) return "/assets/images/no-image.png";

  // Already absolute
  if (image.startsWith("/food_images/")) {
    return image;
  }

  // Filename only
  return `/food_images/${image}`;
}

async function deleteFood(id) {
  if (!confirm("Are you sure you want to delete this food item?")) return;

  try {
    await fetch(`/admin/foods/${id}`, {
      method: "DELETE",
      headers: {
        Authorization: "Bearer " + token
      }
    });

    loadFoods();
  } catch (err) {
    alert("Failed to delete food");
  }
}

/* =========================
   RENDER
========================= */
function renderFoods() {
  table.innerHTML = "";

  foods.forEach(f => {
    table.innerHTML += `
      <tr>
        <td>${f.name}</td>
        <td>₹${f.price}</td>
        <td>${f.category || "-"}</td>
        <td>${f.description || "-"}</td>
        <td>${f.is_veg ? "Veg" : "Non-Veg"}</td>
        <td>
          <img src="${resolveImage(f.image)}" width="40" />
        </td>
        <td>${f.available ? "Available" : "Hidden"}</td>
        <td>
          <button onclick="editFood(${f.id})">Edit</button>
          <button class="danger-btn" onclick="deleteFood(${f.id})">
            Delete
          </button>
        </td>
      </tr>
    `;
  });
}

/* =========================
   MODAL
========================= */
function openModal() {
  document.getElementById("foodModal").classList.remove("hidden");
  document.getElementById("modalTitle").innerText = "Add Food";
  clearForm();
}

function closeModal() {
  document.getElementById("foodModal").classList.add("hidden");
}

function clearForm() {
  foodId.value = "";
  foodName.value = "";
  foodPrice.value = "";
  foodCategory.value = "breakfast";
  foodDescription.value = "";
  foodVegetarian.checked = true;
  foodAvailable.checked = true;
  foodImage.value = "";
}

/* =========================
   EDIT
========================= */
function editFood(id) {
  const f = foods.find(x => x.id === id);

  openModal();
  modalTitle.innerText = "Edit Food";

  foodId.value = f.id;
  foodName.value = f.name;
  foodPrice.value = f.price;
  foodCategory.value = f.category || "breakfast";
  foodDescription.value = f.description || "";
  foodVegetarian.checked = f.is_veg === 1;
  foodAvailable.checked = f.available === 1;
}

/* =========================
   SAVE
========================= */
async function saveFood() {
  const formData = new FormData();

  formData.append("name", foodName.value);
  formData.append("price", foodPrice.value);
  formData.append("category", foodCategory.value);
  formData.append("description", foodDescription.value);
  formData.append("is_veg", foodVegetarian.checked ? 1 : 0);
  formData.append("available", foodAvailable.checked ? 1 : 0);

  if (foodImage.files[0]) {
    formData.append("image", foodImage.files[0]);
  }

  const id = foodId.value;
  const url = id ? `/admin/foods/${id}` : "/admin/foods";
  const method = id ? "PUT" : "POST";

  await fetch(url, {
    method,
    headers: { Authorization: "Bearer " + token },
    body: formData
  });

  closeModal();
  loadFoods();
}

/* =========================
   INIT
========================= */
loadFoods();
