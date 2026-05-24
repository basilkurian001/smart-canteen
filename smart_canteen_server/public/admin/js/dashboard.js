// dashboard.js

const table = document.getElementById("ordersTable");
const token = localStorage.getItem("adminToken");

if (!token) {
  window.location.replace("index.html");
}

let allOrders = [];
let searchActive = false;

/* =========================
   HELPERS
========================= */
function normalize(text) {
  return String(text)
    .toLowerCase()
    .replace(/[-\s]/g, "");
}

/* =========================
   LOAD ORDERS
========================= */
async function loadOrders(force = false) {
  try {
    const res = await fetch(`/admin/orders?t=${Date.now()}`, {
      headers: {
        Authorization: "Bearer " + token,
        "Cache-Control": "no-cache",
      },
    });

    const data = await res.json();
    const orders = data.orders || [];

    // Always update internal state
    allOrders = orders;

    // Always update stats (VERY IMPORTANT)
    updateStats(orders);

    // Render table ONLY if not searching OR forced
    if (!searchActive || force) {
      renderOrders(
        orders.filter(o => o.status !== "DELIVERED")
      );

      // Re-apply search if needed
      if (searchActive) {
        filterOrders();
      }
    }

  } catch (err) {
    console.error("Failed to load orders", err);
  }
}

/* =========================
   RENDER ORDERS
========================= */
function renderOrders(orders) {
  table.innerHTML = "";

  orders.forEach(o => {
    const tr = document.createElement("tr");

    tr.dataset.search = normalize(
      `SC-${o.id} ${o.user_name} ${o.status} ${o.total_amount}`
    );

    tr.innerHTML = `
      <td style="white-space: nowrap;"><span class="toggle-arrow" onclick="toggleOrderDetails(${o.id}, this, 5)">▶</span> SC-${String(o.id).padStart(5, "0")}</td>
      <td>${o.user_name || "User"}</td>
      <td>₹${o.total_amount}</td>
      <td>
        <span class="status ${o.status}">
          ${o.status}
        </span>
      </td>
      <td>
        <div class="action-box">
          <select
            data-original="${o.status}"
            onchange="onStatusChange(this)"
          >
            ${statusOption("PLACED", o.status)}
            ${statusOption("PREPARING", o.status)}
            ${statusOption("READY", o.status)}
            ${statusOption("DELIVERED", o.status)}
          </select>

          <button
            class="apply-btn"
            onclick="applyStatus(${o.id}, this)"
            style="display:none"
          >
            Apply
          </button>
        </div>
      </td>
    `;

    table.appendChild(tr);
    if (window.expandedOrders && window.expandedOrders.has(o.id)) {
      toggleOrderDetails(o.id, tr.querySelector('.toggle-arrow'), 5);
    }
  });
}

/* =========================
   STATUS OPTIONS
========================= */
function statusOption(value, current) {
  return `<option value="${value}" ${value === current ? "selected" : ""}>
    ${value}
  </option>`;
}

/* =========================
   STATUS CHANGE HANDLER
========================= */
function onStatusChange(select) {
  const original = select.dataset.original;
  const current = select.value;
  const btn = select.nextElementSibling;

  btn.style.display = original !== current ? "inline-block" : "none";
}

/* =========================
   APPLY STATUS
========================= */
async function applyStatus(orderId, btn) {
  const select = btn.previousElementSibling;
  const status = select.value;

  btn.disabled = true;
  btn.textContent = "Saving...";

  try {
    await fetch(`/admin/orders/${orderId}/status`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer " + token,
      },
      body: JSON.stringify({ status }),
    });

    // Force refresh after update (even if searching)
    loadOrders(true);

  } catch (err) {
    alert("Failed to update order");
  } finally {
    btn.disabled = false;
    btn.textContent = "Apply";
  }
}

/* =========================
   SMART SEARCH
========================= */
function filterOrders() {
  const input = document.getElementById("orderSearch");
  const query = normalize(input.value);

  searchActive = query.length > 0;

  document.querySelectorAll("#ordersTable tr").forEach(row => {
    row.style.display = row.dataset.search.includes(query)
      ? ""
      : "none";
  });

  // If search cleared, re-render table
  if (!searchActive) {
    loadOrders(true);
  }
}

/* =========================
   UPDATE STATS
========================= */
function updateStats(orders) {
  const today = new Date();

  let ordersToday = 0;
  let pending = 0;
  let delivered = 0;
  let revenue = 0;

  orders.forEach(o => {
    // Unix timestamp seconds → ms
    const orderDate = new Date(o.created_at * 1000);

    const isToday =
      orderDate.getFullYear() === today.getFullYear() &&
      orderDate.getMonth() === today.getMonth() &&
      orderDate.getDate() === today.getDate();

    // 📦 Orders placed today (any status)
    if (isToday) {
      ordersToday++;
    }

    // ✅ Delivered vs Pending (all time)
    if (o.status === "DELIVERED") {
      delivered++;

      // 💰 Revenue ONLY if delivered TODAY
      if (isToday) {
        revenue += Number(o.total_amount);
      }
    } else {
      pending++;
    }
  });

  document.getElementById("ordersToday").textContent = ordersToday;
  document.getElementById("pendingOrders").textContent = pending;
  document.getElementById("deliveredOrders").textContent = delivered;
  document.getElementById("revenue").textContent = revenue;
}

/* =========================
   AUTO REFRESH
========================= */
loadOrders();
setInterval(() => loadOrders(), 5000);

/* =========================
   ORDER EXPANSION
========================= */
window.expandedOrders = window.expandedOrders || new Set();
window.orderItemsCache = window.orderItemsCache || {};

async function toggleOrderDetails(orderId, arrowSpan, colspan) {
  const tr = arrowSpan.closest('tr');
  let detailsRow = tr.nextElementSibling;
  
  if (detailsRow && detailsRow.classList.contains('order-details-row')) {
    const isHidden = detailsRow.style.display === 'none';
    detailsRow.style.display = isHidden ? 'table-row' : 'none';
    arrowSpan.classList.toggle('expanded', isHidden);
    if (isHidden) window.expandedOrders.add(orderId);
    else window.expandedOrders.delete(orderId);
    return;
  }
  
  window.expandedOrders.add(orderId);
  arrowSpan.classList.add('expanded');
  
  detailsRow = document.createElement('tr');
  detailsRow.className = 'order-details-row';
  detailsRow.innerHTML = `
    <td colspan="${colspan}">
      <div class="order-details-content">
        <div class="loading-indicator">Loading items...</div>
      </div>
    </td>
  `;
  tr.parentNode.insertBefore(detailsRow, tr.nextSibling);

  if (window.orderItemsCache[orderId]) {
    renderOrderItems(detailsRow, window.orderItemsCache[orderId]);
    return;
  }

  try {
    const adminToken = typeof token !== 'undefined' ? token : localStorage.getItem('adminToken');
    const res = await fetch(`/admin/orders/${orderId}/items`, {
      headers: { Authorization: "Bearer " + adminToken }
    });
    const data = await res.json();
    
    if (data.success) {
      window.orderItemsCache[orderId] = data.items;
      renderOrderItems(detailsRow, data.items);
    } else {
      detailsRow.querySelector('.order-details-content').innerHTML = '<p style="color:red">Failed to load items.</p>';
    }
  } catch (err) {
    detailsRow.querySelector('.order-details-content').innerHTML = '<p style="color:red">Error loading items.</p>';
  }
}

function renderOrderItems(detailsRow, items) {
  if (!items || items.length === 0) {
    detailsRow.querySelector('.order-details-content').innerHTML = '<p>No items found.</p>';
    return;
  }
  
  let html = `<table class="order-details-table">
    <thead>
      <tr>
        <th style="text-align: left;">Item</th>
        <th style="text-align: left;">Price</th>
        <th style="text-align: left;">Quantity</th>
        <th style="text-align: left;">Total</th>
      </tr>
    </thead>
    <tbody>`;
    
  items.forEach(i => {
    html += `<tr>
      <td style="text-align: left;">${i.name}</td>
      <td style="text-align: left;">₹${i.price}</td>
      <td style="text-align: left;">${i.quantity}</td>
      <td style="text-align: left;">₹${i.price * i.quantity}</td>
    </tr>`;
  });
  
  html += '</tbody></table>';
  detailsRow.querySelector('.order-details-content').innerHTML = html;
}
