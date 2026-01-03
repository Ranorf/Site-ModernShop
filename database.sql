-- Xenon download platform schema and sample data
-- PostgreSQL-flavored SQL

-- Drop tables for clean reseed (optional)
DROP TABLE IF EXISTS download_events;
DROP TABLE IF EXISTS download_files;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS faq;
DROP TABLE IF EXISTS features;
DROP TABLE IF EXISTS subscribers;
DROP TABLE IF EXISTS user_subscriptions;
DROP TABLE IF EXISTS bookmarks;
DROP TABLE IF EXISTS login_attempts;
DROP TABLE IF EXISTS password_reset_tokens;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS oauth_accounts;
DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS system_requirements;
DROP TABLE IF EXISTS releases;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS pages;

CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  permissions_json JSONB DEFAULT '[]'::jsonb
);

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role INTEGER REFERENCES roles(id),
  avatar_url TEXT,
  email_verified_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  notify_email BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

CREATE TABLE user_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_token TEXT NOT NULL UNIQUE,
  user_agent TEXT,
  ip_hash TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE oauth_accounts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  provider_user_id TEXT NOT NULL,
  email TEXT,
  profile_json JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (provider, provider_user_id)
);

CREATE TABLE email_verification_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ
);

CREATE TABLE password_reset_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ
);

CREATE TABLE login_attempts (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL,
  ip_hash TEXT,
  success BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX login_attempts_email_idx ON login_attempts(email);

CREATE TABLE releases (
  id SERIAL PRIMARY KEY,
  version TEXT NOT NULL,
  channel TEXT NOT NULL CHECK (channel IN ('Stable', 'Beta', 'Nightly')),
  title TEXT NOT NULL,
  description TEXT,
  changelog TEXT,
  release_date DATE NOT NULL,
  is_published BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX releases_channel_idx ON releases(channel);
CREATE UNIQUE INDEX releases_version_channel_idx ON releases(version, channel);

CREATE TABLE download_files (
  id SERIAL PRIMARY KEY,
  release_id INTEGER NOT NULL REFERENCES releases(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size_mb NUMERIC(10,2) NOT NULL,
  download_url TEXT NOT NULL,
  checksum_sha256 TEXT NOT NULL,
  signature_status TEXT DEFAULT 'signed',
  is_mirror BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX download_files_release_idx ON download_files(release_id);

CREATE TABLE download_events (
  id SERIAL PRIMARY KEY,
  file_id INTEGER NOT NULL REFERENCES download_files(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id),
  ip_hash TEXT NOT NULL,
  user_agent TEXT,
  referrer TEXT,
  country TEXT,
  downloaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX download_events_file_idx ON download_events(file_id);
CREATE INDEX download_events_user_idx ON download_events(user_id);

CREATE TABLE bookmarks (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL, -- release|doc
  target_slug TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, target_type, target_slug)
);

CREATE TABLE user_subscriptions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('Stable', 'Beta', 'Nightly')),
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  notify_email BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, channel)
);

CREATE TABLE system_requirements (
  id SERIAL PRIMARY KEY,
  platform TEXT NOT NULL,
  min_cpu TEXT,
  min_ram_gb INTEGER,
  min_disk_gb INTEGER,
  min_gpu TEXT,
  recommended_cpu TEXT,
  recommended_ram_gb INTEGER,
  recommended_disk_gb INTEGER,
  notes TEXT
);

CREATE TABLE features (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  short_text TEXT NOT NULL,
  icon_key TEXT,
  is_highlighted BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX features_sort_idx ON features(sort_order);

CREATE TABLE faq (
  id SERIAL PRIMARY KEY,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX faq_sort_idx ON faq(sort_order);

CREATE TABLE reviews (
  id SERIAL PRIMARY KEY,
  author_name TEXT NOT NULL,
  author_avatar_url TEXT,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_published BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE comments (
  id SERIAL PRIMARY KEY,
  text TEXT NOT NULL,
  author_name TEXT NOT NULL,
  author_email TEXT,
  release_id INTEGER REFERENCES releases(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_published BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX comments_release_idx ON comments(release_id);

CREATE TABLE subscribers (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  subscribed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
  unsubscribe_token TEXT NOT NULL
);

CREATE TABLE pages (
  id SERIAL PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content_html_or_md TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_published BOOLEAN NOT NULL DEFAULT TRUE
);

-- Seed data

INSERT INTO roles (name, permissions_json) VALUES
  ('admin', '["manage_users","manage_releases","view_stats"]'),
  ('editor', '["manage_releases","edit_pages"]'),
  ('viewer', '["view_stats"]');

INSERT INTO users (email, username, password_hash, role, avatar_url, email_verified_at, is_active, notify_email, last_login_at) VALUES
  ('iris@xenon.dev', 'iris', '$argon2id$v=19$m=65536,t=3,p=1$VGVzdFRlc3Q$fakehash1', 1, 'https://cdn.xenon.dev/avatars/iris.png', NOW() - INTERVAL '2 days', TRUE, TRUE, NOW() - INTERVAL '1 day'),
  ('dima@xenon.dev', 'dima', '$argon2id$v=19$m=65536,t=3,p=1$VGVzdFRlc3Q$fakehash2', 2, NULL, NOW() - INTERVAL '3 days', TRUE, TRUE, NOW() - INTERVAL '2 days'),
  ('guest@xenon.dev', 'guest', '$argon2id$v=19$m=65536,t=3,p=1$VGVzdFRlc3Q$fakehash3', 3, NULL, NULL, TRUE, FALSE, NULL);

INSERT INTO user_sessions (user_id, session_token, user_agent, ip_hash, created_at, expires_at, is_active) VALUES
  (1, 'sess-token-1', 'Mozilla/5.0', 'hash-201', NOW() - INTERVAL '1 hour', NOW() + INTERVAL '6 hours', TRUE),
  (2, 'sess-token-2', 'Mozilla/5.0', 'hash-202', NOW() - INTERVAL '3 hours', NOW() + INTERVAL '3 hours', TRUE);

INSERT INTO oauth_accounts (user_id, provider, provider_user_id, email, profile_json, created_at) VALUES
  (1, 'google', 'google-iris', 'iris@xenon.dev', '{"name":"Iris Vega"}', NOW() - INTERVAL '5 days');

INSERT INTO email_verification_tokens (user_id, token, created_at, expires_at, used_at) VALUES
  (1, 'verify-token-1', NOW() - INTERVAL '3 days', NOW() + INTERVAL '1 day', NOW() - INTERVAL '2 days'),
  (2, 'verify-token-2', NOW() - INTERVAL '1 day', NOW() + INTERVAL '2 days', NULL);

INSERT INTO password_reset_tokens (user_id, token, created_at, expires_at, used_at) VALUES
  (1, 'reset-token-1', NOW() - INTERVAL '4 hours', NOW() + INTERVAL '20 minutes', NULL);

INSERT INTO login_attempts (email, ip_hash, success, created_at) VALUES
  ('iris@xenon.dev', 'hash-301', TRUE, NOW() - INTERVAL '2 hours'),
  ('iris@xenon.dev', 'hash-301', FALSE, NOW() - INTERVAL '3 hours'),
  ('unknown@xenon.dev', 'hash-302', FALSE, NOW() - INTERVAL '1 hour');

INSERT INTO releases (version, channel, title, description, changelog, release_date, is_published) VALUES
  ('1.4.2', 'Stable', 'Xenon 1.4.2', 'Оптимизация ввода и стабильность.', '- Улучшен input lag\n- Исправлены крэши Vulkan\n- Подписанный установщик', '2026-03-12', TRUE),
  ('1.4.0', 'Stable', 'Xenon 1.4.0', 'Новый Control Hub.', '- Новый Control Hub\n- Больше пресетов графики\n- Улучшена работа с WSL2', '2026-02-18', TRUE),
  ('1.3.1', 'Stable', 'Xenon 1.3.1', 'Исправления безопасности.', '- Обновлены зависимости\n- Исправлены уведомления\n- Подпись обновлена', '2025-12-10', TRUE),
  ('1.5.0-beta', 'Beta', 'Xenon 1.5.0 Beta', 'Тестируем Vulkan 2 профили.', '- Экспериментальные профили\n- Новый лайв-логгер\n- Автообновления beta', '2026-04-04', TRUE),
  ('1.4.3-beta', 'Beta', 'Xenon 1.4.3 Beta', 'Гибкий лаунчер.', '- Больше настроек горячих клавиш\n- Лёгкий лаунчер\n- Telemetry off by default', '2026-03-20', TRUE),
  ('1.6.0-nightly', 'Nightly', 'Xenon 1.6.0 Nightly', 'Ночные сборки с трассировкой.', '- Trace overlay\n- Debug HUD\n- Экспериментальный scheduler', '2026-04-20', TRUE),
  ('1.5.1-nightly', 'Nightly', 'Xenon 1.5.1 Nightly', 'Исправления для автообновлений.', '- Fix автозагрузки\n- Улучшено восстановление после краша\n- Больше логов', '2026-04-10', TRUE),
  ('1.5.0', 'Stable', 'Xenon 1.5.0', 'Релиз с Vulkan 2 профилями.', '- Vulkan 2 профили\n- Контроль кеша\n- Быстрая миграция настроек', '2026-04-15', FALSE);

INSERT INTO download_files (release_id, platform, file_name, file_size_mb, download_url, checksum_sha256, signature_status, is_mirror, created_at) VALUES
  (1, 'Windows', 'xenon-1.4.2-setup.exe', 420.50, 'https://cdn.xenon.dev/stable/1.4.2/setup.exe', '8f1c2c1d9c41d2f0be1a705c5a9d87a5c842b613f9a7c2a0f5e4b0d48ef1a001', 'signed', FALSE, NOW()),
  (1, 'Windows', 'xenon-1.4.2-portable.zip', 415.20, 'https://cdn.xenon.dev/stable/1.4.2/portable.zip', '2d9b7ac8c99e5f8d3d3db67162f9a1e5a2349f6b4c3b0f9d3c6a81d19d5fbb02', 'signed', FALSE, NOW()),
  (1, 'Windows', 'xenon-1.4.2-setup-mirror.exe', 420.50, 'https://mirror1.xenon.dev/stable/1.4.2/setup.exe', '8f1c2c1d9c41d2f0be1a705c5a9d87a5c842b613f9a7c2a0f5e4b0d48ef1a001', 'signed', TRUE, NOW()),
  (2, 'Windows', 'xenon-1.4.0-setup.exe', 398.10, 'https://cdn.xenon.dev/stable/1.4.0/setup.exe', '1aa9c3e6f3b9a7f6c4d2e6a8b7c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7', 'signed', FALSE, NOW() - INTERVAL '30 days'),
  (2, 'Windows', 'xenon-1.4.0-portable.zip', 392.40, 'https://cdn.xenon.dev/stable/1.4.0/portable.zip', '7b9a8c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b', 'signed', FALSE, NOW() - INTERVAL '30 days'),
  (4, 'Windows', 'xenon-1.5.0-beta-setup.exe', 430.00, 'https://cdn.xenon.dev/beta/1.5.0/setup.exe', '3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d', 'signed', FALSE, NOW() - INTERVAL '10 days'),
  (4, 'Windows', 'xenon-1.5.0-beta-portable.zip', 426.80, 'https://cdn.xenon.dev/beta/1.5.0/portable.zip', '9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3c2b1a0f9e8d', 'signed', FALSE, NOW() - INTERVAL '10 days'),
  (5, 'Windows', 'xenon-1.4.3-beta-setup.exe', 408.30, 'https://cdn.xenon.dev/beta/1.4.3/setup.exe', 'b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6', 'signed', FALSE, NOW() - INTERVAL '20 days'),
  (6, 'Windows', 'xenon-1.6.0-nightly-setup.exe', 440.75, 'https://cdn.xenon.dev/nightly/1.6.0/setup.exe', 'c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f60718293a4b5c6d7e8f9a0b1c2d3e4f5a', 'unsigned', FALSE, NOW() - INTERVAL '3 days'),
  (6, 'Windows', 'xenon-1.6.0-nightly-mirror.exe', 440.75, 'https://mirror1.xenon.dev/nightly/1.6.0/setup.exe', 'c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f60718293a4b5c6d7e8f9a0b1c2d3e4f5a', 'unsigned', TRUE, NOW() - INTERVAL '3 days'),
  (7, 'Windows', 'xenon-1.5.1-nightly-setup.exe', 436.00, 'https://cdn.xenon.dev/nightly/1.5.1/setup.exe', 'd2e3f4a5b6c7d8e9f0a1b2c3d4e5f60718293a4b5c6d7e8f9a0b1c2d3e4f5a6b', 'unsigned', FALSE, NOW() - INTERVAL '12 days'),
  (3, 'Windows', 'xenon-1.3.1-setup.exe', 360.00, 'https://cdn.xenon.dev/stable/1.3.1/setup.exe', '0a1b2c3d4e5f60718293a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5', 'signed', FALSE, NOW() - INTERVAL '120 days');

INSERT INTO user_subscriptions (user_id, channel, is_enabled, notify_email, created_at) VALUES
  (1, 'Stable', TRUE, TRUE, NOW() - INTERVAL '2 days'),
  (1, 'Beta', TRUE, TRUE, NOW() - INTERVAL '2 days'),
  (2, 'Stable', TRUE, TRUE, NOW() - INTERVAL '3 days'),
  (3, 'Stable', FALSE, FALSE, NOW() - INTERVAL '5 days');

-- 30 download events (mixed users and anonymous)
INSERT INTO download_events (file_id, user_id, ip_hash, user_agent, referrer, country, downloaded_at) VALUES
  (1, 1, 'hash-101', 'Mozilla/5.0 (Windows NT 10.0)', 'https://xenon.dev', 'DE', NOW() - INTERVAL '1 hour'),
  (1, NULL, 'hash-102', 'Mozilla/5.0 (Windows NT 10.0)', 'https://xenon.dev', 'US', NOW() - INTERVAL '2 hours'),
  (2, 2, 'hash-103', 'Mozilla/5.0 (Windows NT 11.0)', 'https://xenon.dev', 'PL', NOW() - INTERVAL '3 hours'),
  (3, NULL, 'hash-104', 'Mozilla/5.0', 'https://mirror1.xenon.dev', 'BR', NOW() - INTERVAL '5 hours'),
  (4, NULL, 'hash-105', 'Mozilla/5.0', 'https://news.xenon.dev', 'US', NOW() - INTERVAL '1 day'),
  (5, 1, 'hash-106', 'Mozilla/5.0', NULL, 'UA', NOW() - INTERVAL '2 days'),
  (6, NULL, 'hash-107', 'Mozilla/5.0', 'https://beta.xenon.dev', 'FR', NOW() - INTERVAL '3 days'),
  (7, NULL, 'hash-108', 'Mozilla/5.0', 'https://beta.xenon.dev', 'GB', NOW() - INTERVAL '4 days'),
  (8, 2, 'hash-109', 'Mozilla/5.0', 'https://blog.xenon.dev', 'DE', NOW() - INTERVAL '5 days'),
  (9, NULL, 'hash-110', 'Mozilla/5.0', 'https://nightly.xenon.dev', 'IN', NOW() - INTERVAL '2 days'),
  (9, NULL, 'hash-111', 'Mozilla/5.0', 'https://nightly.xenon.dev', 'IN', NOW() - INTERVAL '36 hours'),
  (9, NULL, 'hash-112', 'Mozilla/5.0', NULL, 'IN', NOW() - INTERVAL '12 hours'),
  (10, NULL, 'hash-113', 'Mozilla/5.0', 'https://mirror1.xenon.dev', 'JP', NOW() - INTERVAL '1 day'),
  (10, NULL, 'hash-114', 'Mozilla/5.0', NULL, 'JP', NOW() - INTERVAL '6 hours'),
  (11, 3, 'hash-115', 'Mozilla/5.0', 'https://nightly.xenon.dev', 'CA', NOW() - INTERVAL '8 hours'),
  (11, NULL, 'hash-116', 'Mozilla/5.0', NULL, 'CA', NOW() - INTERVAL '18 hours'),
  (5, NULL, 'hash-117', 'Mozilla/5.0', NULL, 'NL', NOW() - INTERVAL '7 days'),
  (4, NULL, 'hash-118', 'Mozilla/5.0', 'https://rss.xenon.dev', 'US', NOW() - INTERVAL '8 days'),
  (2, NULL, 'hash-119', 'Mozilla/5.0', NULL, 'FR', NOW() - INTERVAL '9 days'),
  (1, NULL, 'hash-120', 'Mozilla/5.0', NULL, 'IT', NOW() - INTERVAL '10 days'),
  (1, NULL, 'hash-121', 'Mozilla/5.0', NULL, 'IT', NOW() - INTERVAL '11 days'),
  (6, NULL, 'hash-122', 'Mozilla/5.0', NULL, 'PT', NOW() - INTERVAL '12 days'),
  (7, NULL, 'hash-123', 'Mozilla/5.0', NULL, 'PT', NOW() - INTERVAL '13 days'),
  (8, NULL, 'hash-124', 'Mozilla/5.0', NULL, 'ES', NOW() - INTERVAL '14 days'),
  (9, NULL, 'hash-125', 'Mozilla/5.0', NULL, 'ES', NOW() - INTERVAL '15 days'),
  (10, NULL, 'hash-126', 'Mozilla/5.0', NULL, 'ES', NOW() - INTERVAL '16 days'),
  (11, NULL, 'hash-127', 'Mozilla/5.0', NULL, 'ES', NOW() - INTERVAL '17 days'),
  (3, NULL, 'hash-128', 'Mozilla/5.0', NULL, 'US', NOW() - INTERVAL '18 days'),
  (2, NULL, 'hash-129', 'Mozilla/5.0', NULL, 'US', NOW() - INTERVAL '19 days'),
  (4, NULL, 'hash-130', 'Mozilla/5.0', NULL, 'US', NOW() - INTERVAL '20 days');

INSERT INTO bookmarks (user_id, target_type, target_slug, created_at) VALUES
  (1, 'release', '1.4.2', NOW() - INTERVAL '2 days'),
  (1, 'doc', 'install', NOW() - INTERVAL '1 day'),
  (2, 'release', '1.5.0-beta', NOW() - INTERVAL '3 days');

INSERT INTO system_requirements (platform, min_cpu, min_ram_gb, min_disk_gb, min_gpu, recommended_cpu, recommended_ram_gb, recommended_disk_gb, notes) VALUES
  ('Windows', '4-core CPU with virtualization', 8, 5, 'DX11/Vulkan, 2GB VRAM', '6-core CPU with virtualization', 16, 10, 'SSD обязательно; отключите Hyper-V или включите WSL2 совместимость.');

INSERT INTO features (title, short_text, icon_key, is_highlighted, sort_order) VALUES
  ('Performance Boost', 'Оптимизированный рендер и низкий input lag.', 'speed', TRUE, 1),
  ('Гибкие профили', 'Готовые пресеты под шутеры, MOBA и автоматику.', 'presets', TRUE, 2),
  ('Улучшенный запуск', 'Детектор конфликтов драйверов и авто-восстановление.', 'boot', TRUE, 3),
  ('Чистый интерфейс', 'Без лишних сервисов и баннеров.', 'ui', FALSE, 4),
  ('Контроль кеша', 'Быстрая очистка и перенос кеша игр.', 'cache', FALSE, 5),
  ('Безопасные обновления', 'Подписанные сборки и проверка хэшей.', 'shield', TRUE, 6);

INSERT INTO faq (question, answer, sort_order, is_published) VALUES
  ('Как установить Xenon?', 'Скачайте установщик, проверьте цифровую подпись Xenon Labs и следуйте шагам мастера.', 1, TRUE),
  ('Можно ли ставить рядом с BlueStacks?', 'Да, Xenon устанавливается отдельно и не трогает основной клиент.', 2, TRUE),
  ('Как обновляться?', 'Скачайте новую сборку, профили настроек сохранятся автоматически.', 3, TRUE),
  ('Что делать с Hyper-V?', 'Отключите Hyper-V или включите режим совместимости в настройках Xenon.', 4, TRUE),
  ('Есть ли телеметрия?', 'Нет, телеметрия отключена. Логи хранятся локально и могут быть очищены.', 5, TRUE),
  ('Поддерживается ли стриминг?', 'Да, рекомендуем 16 ГБ ОЗУ и GPU с аппаратным кодированием H.264/H.265.', 6, TRUE),
  ('Где релиз-ноты?', 'Смотрите раздел Release Notes в панели загрузок или на сайте.', 7, TRUE),
  ('Работает ли на ноутбуках?', 'Да, при наличии виртуализации и актуальных драйверов GPU.', 8, TRUE),
  ('Есть portable-версия?', 'Да, доступен portable архив для Windows.', 9, TRUE),
  ('Как проверить хэш?', 'Используйте SHA-256 из раздела загрузки и сравните с выводом вашей утилиты.', 10, TRUE);

INSERT INTO reviews (author_name, author_avatar_url, rating, text, created_at, is_published) VALUES
  ('Iris Vega', 'https://cdn.xenon.dev/avatars/iris.png', 5, 'Очень ровная сборка, input lag стал меньше.', NOW() - INTERVAL '2 days', TRUE),
  ('Dima K', NULL, 4, 'Control Hub удобный, но хочу больше hotkeys.', NOW() - INTERVAL '4 days', TRUE),
  ('Alex Chen', NULL, 5, 'Вулкан-профиль ускорил Genshin, доволен.', NOW() - INTERVAL '6 days', TRUE),
  ('Maria L', NULL, 4, 'Понравился чистый интерфейс, без рекламы.', NOW() - INTERVAL '8 days', TRUE),
  ('Leo Park', NULL, 5, 'Работает стабильно для стриминга.', NOW() - INTERVAL '10 days', TRUE),
  ('Anya', NULL, 3, 'Portable ок, но размер большой.', NOW() - INTERVAL '12 days', TRUE),
  ('Rui', NULL, 4, 'Автообновление beta работает хорошо.', NOW() - INTERVAL '14 days', TRUE),
  ('Samir', NULL, 5, 'Installer с подписью — доверие сразу.', NOW() - INTERVAL '16 days', TRUE),
  ('Tala', NULL, 4, 'Легко настроить под MOBA.', NOW() - INTERVAL '18 days', TRUE),
  ('Chris', NULL, 5, 'Nightly с трассировкой помогла дебагу.', NOW() - INTERVAL '20 days', TRUE),
  ('Diego', NULL, 4, 'Кеш-контроль экономит время.', NOW() - INTERVAL '22 days', TRUE),
  ('Hana', NULL, 5, 'Лучший эмулятор для моей GPU.', NOW() - INTERVAL '24 days', TRUE);

INSERT INTO comments (text, author_name, author_email, release_id, created_at, is_published) VALUES
  ('Работает на Ryzen 5600 без проблем.', 'Mark', 'mark@example.com', 1, NOW() - INTERVAL '3 days', TRUE),
  ('Жду macOS порт.', 'Ilya', NULL, 1, NOW() - INTERVAL '4 days', TRUE),
  ('Beta стабильнее, чем ожидал.', 'Omar', NULL, 4, NOW() - INTERVAL '5 days', TRUE),
  ('Nightly 1.6.0 запускается быстро.', 'Nina', NULL, 6, NOW() - INTERVAL '2 days', TRUE);

INSERT INTO subscribers (email, subscribed_at, is_confirmed, unsubscribe_token) VALUES
  ('user1@example.com', NOW() - INTERVAL '1 day', TRUE, 'token-1'),
  ('user2@example.com', NOW() - INTERVAL '2 days', TRUE, 'token-2'),
  ('user3@example.com', NOW() - INTERVAL '3 days', FALSE, 'token-3'),
  ('user4@example.com', NOW() - INTERVAL '4 days', TRUE, 'token-4'),
  ('user5@example.com', NOW() - INTERVAL '5 days', FALSE, 'token-5'),
  ('user6@example.com', NOW() - INTERVAL '6 days', TRUE, 'token-6'),
  ('user7@example.com', NOW() - INTERVAL '7 days', TRUE, 'token-7'),
  ('user8@example.com', NOW() - INTERVAL '8 days', TRUE, 'token-8'),
  ('user9@example.com', NOW() - INTERVAL '9 days', TRUE, 'token-9'),
  ('user10@example.com', NOW() - INTERVAL '10 days', TRUE, 'token-10'),
  ('user11@example.com', NOW() - INTERVAL '11 days', FALSE, 'token-11'),
  ('user12@example.com', NOW() - INTERVAL '12 days', TRUE, 'token-12'),
  ('user13@example.com', NOW() - INTERVAL '13 days', TRUE, 'token-13'),
  ('user14@example.com', NOW() - INTERVAL '14 days', TRUE, 'token-14'),
  ('user15@example.com', NOW() - INTERVAL '15 days', TRUE, 'token-15'),
  ('user16@example.com', NOW() - INTERVAL '16 days', TRUE, 'token-16'),
  ('user17@example.com', NOW() - INTERVAL '17 days', TRUE, 'token-17'),
  ('user18@example.com', NOW() - INTERVAL '18 days', TRUE, 'token-18'),
  ('user19@example.com', NOW() - INTERVAL '19 days', TRUE, 'token-19'),
  ('user20@example.com', NOW() - INTERVAL '20 days', TRUE, 'token-20'),
  ('user21@example.com', NOW() - INTERVAL '21 days', TRUE, 'token-21'),
  ('user22@example.com', NOW() - INTERVAL '22 days', TRUE, 'token-22'),
  ('user23@example.com', NOW() - INTERVAL '23 days', TRUE, 'token-23'),
  ('user24@example.com', NOW() - INTERVAL '24 days', TRUE, 'token-24'),
  ('user25@example.com', NOW() - INTERVAL '25 days', TRUE, 'token-25'),
  ('user26@example.com', NOW() - INTERVAL '26 days', TRUE, 'token-26'),
  ('user27@example.com', NOW() - INTERVAL '27 days', TRUE, 'token-27'),
  ('user28@example.com', NOW() - INTERVAL '28 days', TRUE, 'token-28'),
  ('user29@example.com', NOW() - INTERVAL '29 days', TRUE, 'token-29'),
  ('user30@example.com', NOW() - INTERVAL '30 days', TRUE, 'token-30'),
  ('user31@example.com', NOW() - INTERVAL '31 days', TRUE, 'token-31'),
  ('user32@example.com', NOW() - INTERVAL '32 days', TRUE, 'token-32'),
  ('user33@example.com', NOW() - INTERVAL '33 days', TRUE, 'token-33'),
  ('user34@example.com', NOW() - INTERVAL '34 days', TRUE, 'token-34'),
  ('user35@example.com', NOW() - INTERVAL '35 days', TRUE, 'token-35'),
  ('user36@example.com', NOW() - INTERVAL '36 days', TRUE, 'token-36'),
  ('user37@example.com', NOW() - INTERVAL '37 days', TRUE, 'token-37'),
  ('user38@example.com', NOW() - INTERVAL '38 days', TRUE, 'token-38'),
  ('user39@example.com', NOW() - INTERVAL '39 days', TRUE, 'token-39'),
  ('user40@example.com', NOW() - INTERVAL '40 days', TRUE, 'token-40'),
  ('user41@example.com', NOW() - INTERVAL '41 days', TRUE, 'token-41'),
  ('user42@example.com', NOW() - INTERVAL '42 days', TRUE, 'token-42'),
  ('user43@example.com', NOW() - INTERVAL '43 days', TRUE, 'token-43'),
  ('user44@example.com', NOW() - INTERVAL '44 days', TRUE, 'token-44'),
  ('user45@example.com', NOW() - INTERVAL '45 days', TRUE, 'token-45'),
  ('user46@example.com', NOW() - INTERVAL '46 days', TRUE, 'token-46'),
  ('user47@example.com', NOW() - INTERVAL '47 days', TRUE, 'token-47'),
  ('user48@example.com', NOW() - INTERVAL '48 days', TRUE, 'token-48'),
  ('user49@example.com', NOW() - INTERVAL '49 days', TRUE, 'token-49'),
  ('user50@example.com', NOW() - INTERVAL '50 days', TRUE, 'token-50');

INSERT INTO pages (slug, title, content_html_or_md, updated_at, is_published) VALUES
  ('privacy', 'Privacy Policy', '<p>Мы храним только то, что нужно для загрузок и подписки.</p>', NOW(), TRUE),
  ('terms', 'Terms of Service', '<p>Используя Xenon, вы соглашаетесь с минимальной телеметрией (отключена).</p>', NOW(), TRUE),
  ('contact', 'Contact', '<p>Свяжитесь с Xenon Labs: hello@xenon.dev</p>', NOW(), TRUE);
