const FOLDERS = {
  shared: 'shared',
  important: 'important',
  tired: 'tired',
};

const PEOPLE = [
  { id: 'mika', name: 'Mika', avatar: 'み', bio: 'UXと働き方の記事が好き' },
  { id: 'ren', name: 'Ren', avatar: 'れ', bio: 'AI・開発・プロダクトを収集' },
  { id: 'sora', name: 'Sora', avatar: 'そ', bio: '社会とカルチャーを読む' },
];

const SAMPLE_IMAGES = {
  design: [
    'https://images.unsplash.com/photo-1558655146-9f40138edfeb?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=900&q=80',
  ],
  ai: [
    'https://images.unsplash.com/photo-1677442136019-21780ecad995?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=900&q=80',
  ],
  library: [
    'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=900&q=80',
  ],
  web: [
    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=900&q=80',
  ],
};

const SAMPLE_ARTICLES = [
  {
    id: 'friend-1',
    ownerId: 'mika',
    ownerName: 'Mika',
    url: 'https://example.com/design-systems',
    title: '小さなチームで育てるデザインシステム',
    folder: FOLDERS.shared,
    memo: 'コンポーネント棚卸しの参考にする',
    images: SAMPLE_IMAGES.design,
    likes: 18,
    createdAt: Date.now() - 900000,
  },
  {
    id: 'friend-2',
    ownerId: 'ren',
    ownerName: 'Ren',
    url: 'https://example.com/ai-agents-productivity',
    title: 'AIエージェントで変わる個人の生産性',
    folder: FOLDERS.shared,
    memo: '週末に読む',
    images: SAMPLE_IMAGES.ai,
    likes: 31,
    createdAt: Date.now() - 1800000,
  },
  {
    id: 'friend-3',
    ownerId: 'sora',
    ownerName: 'Sora',
    url: 'https://example.com/public-libraries',
    title: '公共図書館とデジタルアーカイブの未来',
    folder: FOLDERS.shared,
    memo: '共有したい',
    images: SAMPLE_IMAGES.library,
    likes: 12,
    createdAt: Date.now() - 3600000,
  },
];

const MY_INITIAL_ARTICLES = [
  {
    id: 'mine-1',
    ownerId: 'me',
    ownerName: 'You',
    url: 'https://developer.mozilla.org/ja/docs/Web/API/Pointer_events',
    title: 'Pointer events - Web API | MDN',
    folder: FOLDERS.important,
    memo: 'スワイプUI実装の確認',
    images: SAMPLE_IMAGES.web,
    likes: 7,
    createdAt: Date.now() - 120000,
  },
];

let state = loadState();
let activePage = 'feed';

function loadState() {
  const stored = localStorage.getItem('save-share-state');
  if (stored) return migrateState(JSON.parse(stored));
  return {
    currentUser: { id: 'me', name: 'You' },
    following: ['mika', 'ren'],
    articles: [...MY_INITIAL_ARTICLES, ...SAMPLE_ARTICLES],
    likedArticleIds: [],
  };
}

function migrateState(current) {
  return {
    ...current,
    articles: current.articles.map((article) => ({
      ...article,
      images: Array.isArray(article.images) && article.images.length ? article.images : inferArticleImages(article.url, article.title),
    })),
  };
}

function saveState() {
  localStorage.setItem('save-share-state', JSON.stringify(state));
}

function setState(updater) {
  state = typeof updater === 'function' ? updater(state) : updater;
  saveState();
  render();
}

function inferTitle(url) {
  try {
    const parsed = new URL(url);
    return parsed.hostname.replace(/^www\./, '') + parsed.pathname.replace(/\/$/, '').replaceAll('/', ' / ');
  } catch {
    return url;
  }
}

function inferArticleImages(url, title = '') {
  const value = `${url} ${title}`.toLowerCase();
  if (/\.(png|jpe?g|webp|gif|avif)(\?.*)?$/.test(url)) return [url];
  if (value.includes('design')) return SAMPLE_IMAGES.design;
  if (value.includes('ai') || value.includes('agent')) return SAMPLE_IMAGES.ai;
  if (value.includes('library') || value.includes('archive')) return SAMPLE_IMAGES.library;
  return SAMPLE_IMAGES.web;
}

function getCollections() {
  const myArticles = state.articles.filter((article) => article.ownerId === 'me');
  const importantArticles = myArticles.filter((article) => article.folder === FOLDERS.important);
  const tiredArticles = myArticles.filter((article) => article.folder === FOLDERS.tired);
  const sharedMine = myArticles.filter((article) => article.folder === FOLDERS.shared);
  const feedArticles = state.articles
    .filter((article) => article.folder === FOLDERS.shared)
    .filter((article) => article.ownerId === 'me' || state.following.includes(article.ownerId))
    .sort((a, b) => b.likes - a.likes || b.createdAt - a.createdAt);
  return { importantArticles, tiredArticles, sharedMine, feedArticles };
}

function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  Object.entries(attrs).forEach(([key, value]) => {
    if (value === undefined || value === null) return;
    if (key === 'className') node.className = value;
    else if (key === 'text') node.textContent = value;
    else if (key.startsWith('on')) node.addEventListener(key.slice(2).toLowerCase(), value);
    else node.setAttribute(key, value);
  });
  const childList = Array.isArray(children) ? children : [children];
  childList.forEach((child) => {
    if (child === undefined || child === null) return;
    node.append(child.nodeType ? child : document.createTextNode(child));
  });
  return node;
}

function render() {
  const root = document.getElementById('root');
  const { importantArticles, tiredArticles, sharedMine, feedArticles } = getCollections();
  root.innerHTML = '';

  const shell = el('main', { className: 'app-shell' });
  shell.append(renderHero(), renderTabs({ importantArticles, tiredArticles, feedArticles }));

  if (activePage === 'feed') {
    const content = document.createDocumentFragment();
    content.append(renderArticleList(feedArticles, 'まだ何もありません', (article) => renderArticleCard({
      article,
      ownerLabel: article.ownerId === 'me' ? '自分' : article.ownerName,
      actions: [
        actionButton('保存', () => saveFromFeed(article)),
        actionButton(`♥ ${article.likes}`, () => toggleLike(article.id), state.likedArticleIds.includes(article.id) ? 'liked' : 'ghost'),
      ],
    })));
    if (sharedMine.length > 0) content.append(el('p', { className: 'small-note', text: `共有中 ${sharedMine.length}件` }));
    shell.append(renderPage('フィード', 'みんなのおすすめ', content));
  }

  if (activePage === 'private') {
    shell.append(renderPage(
      '重要',
      '左で共有、右でゴミ箱',
      renderArticleList(importantArticles, '重要は空です', (article) => renderArticleCard({
        article,
        showMemo: true,
        leftHint: '共有',
        rightHint: 'ゴミ箱',
        onSwipeLeft: () => updateArticle(article.id, { folder: FOLDERS.shared }),
        onSwipeRight: () => updateArticle(article.id, { folder: FOLDERS.tired }),
        onMemo: (memo) => updateArticle(article.id, { memo }),
        actions: [
          actionButton('共有', () => updateArticle(article.id, { folder: FOLDERS.shared })),
          actionButton('ゴミ箱', () => updateArticle(article.id, { folder: FOLDERS.tired }), 'ghost'),
        ],
      })),
    ));
  }

  if (activePage === 'trash') {
    shell.append(renderPage(
      'ゴミ箱',
      '戻すか削除',
      renderArticleList(tiredArticles, 'ゴミ箱は空です', (article) => renderArticleCard({
        article,
        showMemo: true,
        rightHint: '削除',
        onSwipeRight: () => deleteArticle(article.id),
        onMemo: (memo) => updateArticle(article.id, { memo }),
        actions: [
          actionButton('戻す', () => updateArticle(article.id, { folder: FOLDERS.important })),
          actionButton('削除', () => deleteArticle(article.id), 'danger'),
        ],
      })),
    ));
  }

  root.append(shell);
}

function renderHero() {
  const section = el('section', { className: 'hero' });
  const copy = el('div', { className: 'hero-copy-block' }, [
    el('p', { className: 'eyebrow', text: 'Save & Share' }),
    el('h1', { text: '読みたいを、きれいに残す。' }),
    el('p', { className: 'hero-copy', text: '保存、共有、整理。必要な操作だけ。' }),
  ]);
  const form = el('form', { className: 'upload-card', onsubmit: addArticle }, [
    el('label', {}, ['URL', el('input', { id: 'article-url', placeholder: 'https://example.com/article' })]),
    el('label', {}, ['タイトル', el('input', { id: 'article-title', placeholder: '任意' })]),
    el('button', { type: 'submit', text: '重要に追加' }),
  ]);
  section.append(copy, form);
  return section;
}

function renderTabs({ importantArticles, tiredArticles, feedArticles }) {
  return el('nav', { className: 'tabs', 'aria-label': 'ページ切り替え' }, [
    tab('feed', 'フィード', feedArticles.length),
    tab('private', '重要', importantArticles.length),
    tab('trash', 'ゴミ箱', tiredArticles.length),
  ]);
}

function tab(page, label, count) {
  return el('button', {
    className: activePage === page ? 'tab active' : 'tab',
    onclick: () => { activePage = page; render(); },
  }, [label, el('span', { text: count })]);
}

function renderPage(title, description, content) {
  return el('section', { className: 'page-card' }, [
    el('div', { className: 'page-heading' }, [el('h2', { text: title }), el('p', { text: description })]),
    content,
  ]);
}

function renderArticleList(articles, empty, renderCard) {
  if (articles.length === 0) return el('div', { className: 'empty-state', text: empty });
  return el('div', { className: 'article-list' }, articles.map(renderCard));
}

function renderArticleCard({ article, actions, showMemo = false, ownerLabel, onMemo, onSwipeLeft, onSwipeRight, leftHint, rightHint }) {
  let startX = null;
  let dragX = 0;
  const host = safeHost(article.url);
  const images = Array.isArray(article.images) ? article.images : [];
  const card = el('article', { className: 'article-card' });

  card.addEventListener('pointerdown', (event) => {
    startX = event.clientX;
    card.setPointerCapture?.(event.pointerId);
  });
  card.addEventListener('pointermove', (event) => {
    if (startX === null) return;
    dragX = event.clientX - startX;
    card.style.transform = `translateX(${dragX}px) rotate(${dragX / 36}deg)`;
  });
  const endSwipe = () => {
    if (dragX < -90 && onSwipeLeft) onSwipeLeft();
    if (dragX > 90 && onSwipeRight) onSwipeRight();
    startX = null;
    dragX = 0;
    card.style.transform = '';
  };
  card.addEventListener('pointerup', endSwipe);
  card.addEventListener('pointercancel', endSwipe);

  if (leftHint || rightHint) {
    card.append(el('div', { className: 'swipe-hints' }, [el('span', { text: leftHint ? `← ${leftHint}` : '' }), el('span', { text: rightHint ? `${rightHint} →` : '' })]));
  }

  if (images.length > 0) {
    card.append(el('div', { className: images.length > 1 ? 'image-strip' : 'image-strip single' }, images.slice(0, 3).map((imageUrl, index) => (
      el('figure', { className: 'image-card' }, [
        el('img', { src: imageUrl, alt: `${article.title} の画像 ${index + 1}`, loading: 'lazy' }),
      ])
    ))));
  }

  card.append(
    el('div', { className: 'card-topline' }, [el('span', { text: ownerLabel || '重要' }), el('span', { text: host })]),
    el('a', { className: 'article-title', href: article.url, target: '_blank', rel: 'noreferrer', text: article.title }),
  );

  if (showMemo) {
    const textarea = el('textarea', { placeholder: 'メモ' });
    textarea.value = article.memo;
    textarea.addEventListener('input', (event) => onMemo(event.target.value));
    card.append(el('label', { className: 'memo-box' }, ['メモ', textarea]));
  }

  card.append(el('div', { className: 'card-actions' }, actions));
  return card;
}

function actionButton(text, onClick, className = '') {
  return el('button', { className, onclick: onClick, text });
}

function addArticle(event) {
  event.preventDefault();
  const urlInput = document.getElementById('article-url');
  const titleInput = document.getElementById('article-title');
  const cleanUrl = urlInput.value.trim();
  if (!cleanUrl) return;
  const normalizedUrl = cleanUrl.startsWith('http') ? cleanUrl : `https://${cleanUrl}`;
  const title = titleInput.value.trim() || inferTitle(normalizedUrl);
  const article = {
    id: `mine-${crypto.randomUUID()}`,
    ownerId: 'me',
    ownerName: 'You',
    url: normalizedUrl,
    title,
    folder: FOLDERS.important,
    memo: '',
    images: inferArticleImages(normalizedUrl, title),
    likes: 0,
    createdAt: Date.now(),
  };
  activePage = 'private';
  setState((current) => ({ ...current, articles: [article, ...current.articles] }));
}

function updateArticle(id, patch) {
  setState((current) => ({
    ...current,
    articles: current.articles.map((article) => (article.id === id ? { ...article, ...patch } : article)),
  }));
}

function deleteArticle(id) {
  setState((current) => ({
    ...current,
    articles: current.articles.filter((article) => article.id !== id),
    likedArticleIds: current.likedArticleIds.filter((likedId) => likedId !== id),
  }));
}

function saveFromFeed(article) {
  const alreadySaved = state.articles.some((candidate) => candidate.ownerId === 'me' && candidate.url === article.url && candidate.folder !== FOLDERS.tired);
  if (alreadySaved) return;
  const copy = {
    ...article,
    id: `mine-${crypto.randomUUID()}`,
    ownerId: 'me',
    ownerName: 'You',
    folder: FOLDERS.important,
    memo: '',
    likes: 0,
    createdAt: Date.now(),
  };
  activePage = 'private';
  setState((current) => ({ ...current, articles: [copy, ...current.articles] }));
}

function toggleLike(articleId) {
  const liked = state.likedArticleIds.includes(articleId);
  setState((current) => ({
    ...current,
    likedArticleIds: liked ? current.likedArticleIds.filter((id) => id !== articleId) : [...current.likedArticleIds, articleId],
    articles: current.articles.map((article) => (
      article.id === articleId ? { ...article, likes: Math.max(0, article.likes + (liked ? -1 : 1)) } : article
    )),
  }));
}

function safeHost(url) {
  try {
    return new URL(url).hostname.replace(/^www\./, '');
  } catch {
    return url;
  }
}

render();