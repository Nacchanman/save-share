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

const SAMPLE_ARTICLES = [
  {
    id: 'friend-1',
    ownerId: 'mika',
    ownerName: 'Mika',
    url: 'https://example.com/design-systems',
    title: '小さなチームで育てるデザインシステム',
    folder: FOLDERS.shared,
    memo: 'あとでコンポーネント棚卸しの参考にする',
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
    memo: 'スワイプUI実装の確認に使う',
    likes: 7,
    createdAt: Date.now() - 120000,
  },
];

let state = loadState();
let activePage = 'private';

function loadState() {
  const stored = localStorage.getItem('save-share-state');
  if (stored) return JSON.parse(stored);
  return {
    currentUser: { id: 'me', name: 'You' },
    following: ['mika', 'ren'],
    articles: [...MY_INITIAL_ARTICLES, ...SAMPLE_ARTICLES],
    likedArticleIds: [],
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

  if (activePage === 'private') {
    shell.append(renderPage(
      '重要フォルダ',
      '左スワイプで共有フォルダ、右スワイプで「もういいフォルダ」に移動します。',
      renderArticleList(importantArticles, '重要フォルダは空です。上のフォームからURLを追加してください。', (article) => renderArticleCard({
        article,
        showMemo: true,
        leftHint: '共有へ',
        rightHint: 'もういいへ',
        onSwipeLeft: () => updateArticle(article.id, { folder: FOLDERS.shared }),
        onSwipeRight: () => updateArticle(article.id, { folder: FOLDERS.tired }),
        onMemo: (memo) => updateArticle(article.id, { memo }),
        actions: [
          actionButton('共有へ', () => updateArticle(article.id, { folder: FOLDERS.shared })),
          actionButton('もういい', () => updateArticle(article.id, { folder: FOLDERS.tired }), 'ghost'),
        ],
      })),
    ));
  }

  if (activePage === 'feed') {
    const content = document.createDocumentFragment();
    content.append(renderArticleList(feedArticles, 'フィードは空です。友達をフォローするか、記事を共有してください。', (article) => renderArticleCard({
      article,
      ownerLabel: article.ownerId === 'me' ? 'あなたの共有' : `${article.ownerName} の共有`,
      actions: [
        actionButton('セーブ', () => saveFromFeed(article)),
        actionButton(`♥ ${article.likes}`, () => toggleLike(article.id), state.likedArticleIds.includes(article.id) ? 'liked' : 'ghost'),
      ],
    })));
    if (sharedMine.length > 0) content.append(el('p', { className: 'small-note', text: `あなたの共有フォルダ: ${sharedMine.length}件が友達のフィードに表示されます。` }));
    shell.append(renderPage('共有フォルダ / フィード', '自分とフォロー中の友達の共有記事を、いいねが多い順に表示します。メモは非表示です。', content));
  }

  if (activePage === 'trash') {
    shell.append(renderPage(
      'もういいフォルダ / トラッシュ',
      '右スワイプで削除フォルダへ送り、データベース（このデモではローカル保存）から完全削除します。',
      renderArticleList(tiredArticles, 'トラッシュは空です。', (article) => renderArticleCard({
        article,
        showMemo: true,
        rightHint: '完全削除',
        onSwipeRight: () => deleteArticle(article.id),
        onMemo: (memo) => updateArticle(article.id, { memo }),
        actions: [
          actionButton('戻す', () => updateArticle(article.id, { folder: FOLDERS.important })),
          actionButton('完全削除', () => deleteArticle(article.id), 'danger'),
        ],
      })),
    ));
  }

  if (activePage === 'friends') {
    shell.append(renderPage('友達をフォロー', 'フォローした友達の共有フォルダだけがフィードページに流れます。', renderFriends()));
  }

  root.append(shell);
}

function renderHero() {
  const section = el('section', { className: 'hero' });
  const copy = el('div', {}, [
    el('p', { className: 'eyebrow', text: 'Save & Share' }),
    el('h1', { text: '読みたい記事を保存し、スワイプで共有・整理する。' }),
    el('p', { className: 'hero-copy', text: 'URLをアップロードすると重要フォルダへ追加。左スワイプで共有、右スワイプで「もういい」へ。友達の共有記事はフィードで読めます。' }),
  ]);
  const form = el('form', { className: 'upload-card', onsubmit: addArticle }, [
    el('label', {}, ['記事URL', el('input', { id: 'article-url', placeholder: 'https://example.com/article' })]),
    el('label', {}, ['タイトル（任意）', el('input', { id: 'article-title', placeholder: '自動でURLから推定できます' })]),
    el('button', { type: 'submit', text: '重要フォルダに追加' }),
  ]);
  section.append(copy, form);
  return section;
}

function renderTabs({ importantArticles, tiredArticles, feedArticles }) {
  return el('nav', { className: 'tabs', 'aria-label': 'ページ切り替え' }, [
    tab('private', 'プライベート', importantArticles.length),
    tab('feed', 'フィード', feedArticles.length),
    tab('trash', 'トラッシュ', tiredArticles.length),
    tab('friends', '友達', state.following.length),
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
  const card = el('article', { className: 'article-card' });

  card.addEventListener('pointerdown', (event) => {
    startX = event.clientX;
    card.setPointerCapture?.(event.pointerId);
  });
  card.addEventListener('pointermove', (event) => {
    if (startX === null) return;
    dragX = event.clientX - startX;
    card.style.transform = `translateX(${dragX}px) rotate(${dragX / 28}deg)`;
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
  card.append(
    el('div', { className: 'card-topline' }, [el('span', { text: ownerLabel || '重要フォルダ' }), el('span', { text: host })]),
    el('a', { className: 'article-title', href: article.url, target: '_blank', rel: 'noreferrer', text: article.title }),
    el('p', { className: 'article-url', text: article.url }),
  );
  if (showMemo) {
    const textarea = el('textarea', { placeholder: 'この記事について自由にメモ' });
    textarea.value = article.memo;
    textarea.addEventListener('input', (event) => onMemo(event.target.value));
    card.append(el('label', { className: 'memo-box' }, ['メモ', textarea]));
  }
  card.append(el('div', { className: 'card-actions' }, actions));
  return card;
}

function renderFriends() {
  return el('div', { className: 'friend-grid' }, PEOPLE.map((person) => {
    const following = state.following.includes(person.id);
    return el('article', { className: 'friend-card' }, [
      el('div', { className: 'avatar', text: person.avatar }),
      el('div', {}, [el('h3', { text: person.name }), el('p', { text: person.bio })]),
      actionButton(following ? 'フォロー中' : 'フォロー', () => toggleFollow(person.id), following ? 'liked' : ''),
    ]);
  }));
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
  const article = {
    id: `mine-${crypto.randomUUID()}`,
    ownerId: 'me',
    ownerName: 'You',
    url: normalizedUrl,
    title: titleInput.value.trim() || inferTitle(normalizedUrl),
    folder: FOLDERS.important,
    memo: '',
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

function toggleFollow(personId) {
  setState((current) => ({
    ...current,
    following: current.following.includes(personId) ? current.following.filter((id) => id !== personId) : [...current.following, personId],
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
