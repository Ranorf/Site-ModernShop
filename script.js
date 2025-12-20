const products = [
  {
    name: "Лаконічний рюкзак",
    description: "Водостійка тканина, кишеня для ноутбука та прихована блискавка.",
    price: "3 200 грн",
    status: "Новинка"
  },
  {
    name: "Смарт-годинник Urban",
    description: "OLED-дисплей, NFC, тиждень автономності та швидкі ремінці.",
    price: "5 800 грн",
    status: "Хіт"
  },
  {
    name: "Бездротові навушники",
    description: "Активне шумозаглушення, 32 години роботи та магнітний кейс.",
    price: "4 050 грн",
    status: "У наявності"
  },
  {
    name: "Лампа-скульптура",
    description: "Неонова підсвітка, мінімалістична форма та сенсорне керування.",
    price: "2 100 грн",
    status: "Обмежено"
  }
];

const grid = document.getElementById("product-grid");
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("visible");
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.2 });

function renderProducts() {
  products.forEach((product, index) => {
    const card = document.createElement("article");
    card.className = "product reveal";
    card.style.animationDelay = `${index * 80}ms`;
    card.innerHTML = `
      <span class="badge">${product.status}</span>
      <h3>${product.name}</h3>
      <p>${product.description}</p>
      <div class="price">
        <strong>${product.price}</strong>
        <span>Доставка 1-2 дні</span>
      </div>
    `;
    grid.appendChild(card);
    observer.observe(card);
  });
}

function initReveal() {
  document.querySelectorAll(".reveal").forEach((el) => observer.observe(el));
}

renderProducts();
initReveal();
