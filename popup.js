document.addEventListener('DOMContentLoaded', function() {
  const form = document.getElementById('bookmark-form');
  const bookmarkUrlInput = document.getElementById('bookmark-url');
  const bookmarkTiles = document.getElementById('bookmark-tiles');

  form.addEventListener('submit', function(event) {
    event.preventDefault();
    const url = bookmarkUrlInput.value;
    if (url) {
      addBookmark(url);
      bookmarkUrlInput.value = '';
    }
  });

  function addBookmark(url) {
    chrome.storage.sync.get({ bookmarks: [] }, function(data) {
      const bookmarks = data.bookmarks;
      bookmarks.push(url);
      chrome.storage.sync.set({ bookmarks: bookmarks }, function() {
        displayBookmarks(bookmarks);
      });
    });
  }

  function removeBookmark(index) {
    chrome.storage.sync.get({ bookmarks: [] }, function(data) {
      const bookmarks = data.bookmarks;
      bookmarks.splice(index, 1);
      chrome.storage.sync.set({ bookmarks: bookmarks }, function() {
        displayBookmarks(bookmarks);
      });
    });
  }

  function updateBookmark(index, newUrl) {
    chrome.storage.sync.get({ bookmarks: [] }, function(data) {
      const bookmarks = data.bookmarks;
      bookmarks[index] = newUrl;
      chrome.storage.sync.set({ bookmarks: bookmarks }, function() {
        displayBookmarks(bookmarks);
      });
    });
  }

  function displayBookmarks(bookmarks) {
    bookmarkTiles.innerHTML = '';
    bookmarks.forEach(function(bookmark, index) {
      const tile = document.createElement('div');
      tile.classList.add('tile');

      const faviconUrl = new URL(bookmark).origin + '/favicon.ico';
      const link = document.createElement('a');
      link.href = bookmark;
      link.target = '_blank';
      link.title = bookmark; // Show URL on hover
      link.classList.add('favicon-link');

      const favicon = document.createElement('img');
      favicon.src = faviconUrl;
      favicon.alt = 'favicon';
      favicon.classList.add('favicon');

      link.appendChild(favicon);
      tile.appendChild(link);

      // Add event listener for right-click to go to the site
      tile.addEventListener('click', function(event) {
        event.preventDefault();
        chrome.tabs.create({ url: bookmark });
      });

      // Add event listener for left-click to show options to update or remove
      tile.addEventListener('contextmenu', function(event) {
        event.preventDefault();
        displayOptions(tile, index, bookmark);
      });

      bookmarkTiles.appendChild(tile);
    });
  }

  function displayOptions(tile, index, bookmark) {
    // Remove existing options if any
    const existingOptions = document.querySelector('.options');
    if (existingOptions) {
      existingOptions.remove();
    }

    // Create option container
    const options = document.createElement('div');
    options.classList.add('options');

    // Create update button
    const updateButton = document.createElement('button');
    updateButton.textContent = 'Update';
    updateButton.addEventListener('click', function(event) {
      event.stopPropagation();
      const newUrl = prompt('Enter the new URL:', bookmark);
      if (newUrl) {
        updateBookmark(index, newUrl);
      }
    });

    // Create remove button
    const removeButton = document.createElement('button');
    removeButton.textContent = 'Remove';
    removeButton.addEventListener('click', function(event) {
      event.stopPropagation();
      if (confirm('Do you want to remove this bookmark?')) {
        removeBookmark(index);
      }
    });

    options.appendChild(updateButton);
    options.appendChild(removeButton);
    tile.appendChild(options);
  }

  chrome.storage.sync.get({ bookmarks: [] }, function(data) {
    displayBookmarks(data.bookmarks);
  });
});