const header = document.getElementById("site-header");
const cursorDot = document.getElementById("cursor-dot");
const accordions = document.querySelectorAll(".accordion__item");
const navToggle = document.getElementById("nav-toggle");
const navMobile = document.getElementById("nav-mobile");
const faqSearch = document.getElementById("faq-search");
const userToggle = document.getElementById("user-toggle");
const userDropdown = document.getElementById("user-dropdown");
const pageAuth = document.body.getAttribute("data-auth");
const searchBtn = document.getElementById("nav-search-btn");
const searchPanel = document.getElementById("nav-search-panel");
const formatGroups = document.querySelectorAll("[data-format-group]");
const exitModal = document.getElementById("exit-intent");
const exitClose = document.getElementById("exit-close");
const umami = window.umami || null;

if (header) {
  window.addEventListener("scroll", () => {
    header.classList.toggle("scrolled", window.scrollY > 30);
  });
}

if (pageAuth === "signed-in") {
  document.body.classList.add("signed-in");
}

if (cursorDot) {
  document.addEventListener("mousemove", (e) => {
    cursorDot.style.top = `${e.clientY}px`;
    cursorDot.style.left = `${e.clientX}px`;
  });
}

if (navToggle && navMobile) {
  navToggle.addEventListener("click", () => {
    navToggle.classList.toggle("open");
    navMobile.classList.toggle("open");
    if (navMobile.classList.contains("open") && umami) umami("nav_open");
  });

  navMobile.querySelectorAll("a").forEach((link) =>
    link.addEventListener("click", () => {
      navToggle.classList.remove("open");
      navMobile.classList.remove("open");
      if (umami) umami("nav_link", { href: link.getAttribute("href") });
    })
  );
}

accordions.forEach((item) => {
  item.addEventListener("click", () => {
    const expanded = item.getAttribute("aria-expanded") === "true";
    accordions.forEach((btn) => btn.setAttribute("aria-expanded", "false"));
    item.setAttribute("aria-expanded", String(!expanded));
  });
});

if (faqSearch) {
  faqSearch.addEventListener("input", (e) => {
    const term = e.target.value.toLowerCase();
    const faqItems = document.querySelectorAll(".faq-item");
    faqItems.forEach((item) => {
      const text = item.innerText.toLowerCase();
      item.style.display = text.includes(term) ? "grid" : "none";
    });
    if (umami) umami("faq_search");
  });
}

if (userToggle && userDropdown) {
  userToggle.addEventListener("click", () => {
    userDropdown.classList.toggle("open");
  });

  document.addEventListener("click", (e) => {
    if (!userDropdown.contains(e.target) && !userToggle.contains(e.target)) {
      userDropdown.classList.remove("open");
    }
  });
}

if (searchBtn && searchPanel) {
  searchBtn.addEventListener("click", () => {
    searchPanel.classList.toggle("open");
    const input = searchPanel.querySelector("input");
    if (searchPanel.classList.contains("open") && input) {
      input.focus();
    }
  });
  document.addEventListener("click", (e) => {
    if (!searchPanel.contains(e.target) && !searchBtn.contains(e.target)) {
      searchPanel.classList.remove("open");
    }
  });
}

formatGroups.forEach((group) => {
  const buttons = group.querySelectorAll("[data-format-target]");
  const panels = (group.parentElement || document).querySelectorAll("[data-format-panel]");
  buttons.forEach((btn) => {
    btn.addEventListener("click", () => {
      const target = btn.getAttribute("data-format-target");
      buttons.forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      panels.forEach((panel) => {
        panel.classList.toggle("hidden", panel.getAttribute("data-format-panel") !== target);
      });
      if (umami) umami("format_switch", { target });
    });
  });
});

const EXIT_KEY = "xenonExitIntentShown";
if (exitModal && !localStorage.getItem(EXIT_KEY)) {
  const handler = (e) => {
    if (e.clientY < 10) {
      exitModal.classList.add("open");
      localStorage.setItem(EXIT_KEY, Date.now().toString());
      document.removeEventListener("mouseleave", handler);
    }
  };
  document.addEventListener("mouseleave", handler);
}

if (exitClose && exitModal) {
  exitClose.addEventListener("click", () => exitModal.classList.remove("open"));
}
