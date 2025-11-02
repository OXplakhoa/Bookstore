// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

// Function to get the anti-forgery token from the hidden input field
function getAntiForgeryToken() {
  const tokenField = document.querySelector(
    'input[name="__RequestVerificationToken"]'
  );
  return tokenField ? tokenField.value : "";
}

// Favorite Toggle Handler
async function handleFavoriteToggle(button) {
  const productId = button.dataset.productId;
  if (!productId) {
    return;
  }

  const token = getAntiForgeryToken();
  if (!token) {
    console.warn("Missing anti-forgery token.");
    return;
  }

  try {
    const response = await fetch("/Favorites/Toggle", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        RequestVerificationToken: token,
      },
      body: JSON.stringify({ productId: parseInt(productId) }),
    });

    if (
      response.status === 401 ||
      (response.redirected && response.url.includes("/Identity/Account/Login"))
    ) {
      window.location.href = "/Identity/Account/Login";
      return;
    }

    if (!response.ok) {
      throw new Error("Failed to toggle favorite");
    }

    const result = await response.json();
    if (!result?.success) {
      return;
    }

    const icon = button.querySelector("i");
    if (!icon) {
      return;
    }

    if (result.isFavorited) {
      icon.classList.remove("fa-regular");
      icon.classList.add("fa-solid", "text-danger");
      button.title = "Remove from Favorites";
      button.setAttribute("aria-label", "Remove from Favorites");
    } else {
      icon.classList.remove("fa-solid", "text-danger");
      icon.classList.add("fa-regular");
      button.title = "Add to Favorites";
      button.setAttribute("aria-label", "Add to Favorites");
    }
  } catch (error) {
    console.error("Favorite toggle failed", error);
  }
}

function initFavoriteToggles() {
  document.addEventListener("click", function (event) {
    const button = event.target.closest(".favorite-toggle");
    if (button) {
      event.preventDefault();
      handleFavoriteToggle(button);
    }
  });
}

document.addEventListener("DOMContentLoaded", function () {
  initFavoriteToggles();
});

// Flash Sale Countdown Timer
(function () {
	// Utility to pad numbers with leading zeros, e.g., 5 -> "05"
  function pad(n) {
    return n < 10 ? "0" + n : n;
  }

  function renderCountdown(el, msLeft) {
    if (msLeft < 0) {
      el.textContent = "Đã kết thúc";
      el.classList.add("text-muted");
	  // Dispatch a custom event to notify that the flash sale has expired, bubbles up the DOM - parent elements can listen for this event
      el.dispatchEvent(new CustomEvent("flashsale:expired", { bubbles: true }));
      return false;
    }

    var totalSeconds = Math.floor(msLeft / 1000);
    var days = Math.floor(totalSeconds / 86400);
    var hours = Math.floor((totalSeconds % 86400) / 3600);
    var minutes = Math.floor((totalSeconds % 3600) / 60);
    var seconds = totalSeconds % 60;

    var parts = [];
    if (days > 0) parts.push(days + "d");
    parts.push(pad(hours) + "h", pad(minutes) + "m", pad(seconds) + "s");

    el.textContent = "Kết thúc trong " + parts.join(", ");
    return true;
  }

  function initOne(el) {
	// Read the sale's end time from the element's 'data-countdown-end' attribute
	// Expected format: ISO 8601 string (e.g., "2025-12-31T23:59:59Z")
    var endIso = el.getAttribute("data-countdown-end");
    if (!endIso) return;

    var end = new Date(endIso);
    if (isNaN(end.getTime())) return;

    function tick() {
      var now = new Date();
      var msLeft = end.getTime() - now.getTime();
      if (!renderCountdown(el, msLeft)) {
        clearInterval(timer);
      }
    }
    tick();
	// Update the countdown every second
    var timer = setInterval(tick, 1000);
  }
  window.initFlashSaleCountdowns = function () {
    document.querySelectorAll("[data-countdown-end").forEach(initOne);
  };
  document.addEventListener("DOMContentLoaded", window.initFlashSaleCountdowns);
});
