'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"flutter_bootstrap.js": "809644839b47d5dfaab3017ddcb73dc1",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"main.dart.js": "2f4d5c00f53153e1b421c87af3287fa2",
"version.json": "dcb3e31dc89554c90b4fa420661062e9",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "7003c03f24380888faea299cc997ca33",
"assets/assets/runes/t/T.png": "111dfb47999c3481a680ee3c4adcaffe",
"assets/assets/runes/a/A.png": "52a04b68caa80bd2a7d7eac633b9bee0",
"assets/assets/runes/y/Y.png": "2b42d40124ef67c32357ac2ac2d5cd11",
"assets/assets/runes/r/R.png": "cfaca90190b45003929ee89b9a651d05",
"assets/assets/runes/u/U.png": "ec2f9c42d89c06f90003d3463bffa7f5",
"assets/assets/runes/b/B.png": "79b66943002c9f29baf42f7b26a0eabe",
"assets/assets/runes/o/O.png": "a2226c0e78b3bcaf55edb57fb4cbc932",
"assets/assets/runes/n/N.png": "1960487b4891319123a7ba2c7c271441",
"assets/assets/runes/q/Q.png": "de0a8379d4deeabb05df09bcadfb6ecc",
"assets/assets/runes/p/P.png": "2438b9bdee81cfc1cd516cda137fd173",
"assets/assets/runes/c/C.png": "ecdf6578d7c78405f676a5f5cf9a9e7c",
"assets/assets/runes/e/E.png": "3f2b1033cc72f6258a5854fbb37a994e",
"assets/assets/runes/f/F.png": "f8ed80bb2f2e1a6b6a2e9ff7b69bd8f6",
"assets/assets/runes/j/J.png": "1ba8183fe18c7ffe246d35d46a9e07f8",
"assets/assets/runes/s/S.png": "91338ad35142ed662f7d277a2e1046f1",
"assets/assets/runes/h/H.png": "fd174b802a87b9dc675c97f22a9d8859",
"assets/assets/runes/i/I.png": "66f08e4b0d5b0a0d942c70a1ebdef9cb",
"assets/assets/runes/z/Z.png": "8302371bb07414a25d50531c59b3b880",
"assets/assets/runes/v/V.png": "dcb5aca89714f28552d91e9e21c7f013",
"assets/assets/runes/d/D.png": "a1a0e29ff453004d400c677b63ef61f8",
"assets/assets/runes/w/W.png": "4ef3493d92abfaba6849a9551b394875",
"assets/assets/runes/g/G.png": "c0b7da9463afaac34ff027e43458ed88",
"assets/assets/runes/x/X.png": "c0ed7ff4e324b5a0c0fc9537bf6a2bae",
"assets/assets/runes/m/M.png": "650264ea1515404e85509ea7c1e3b98e",
"assets/assets/runes/l/L.png": "062270024963385fa4ea6e6a1dac5263",
"assets/assets/runes/k/K.png": "9379f24f4690d66c23b94ce9d2e6d188",
"assets/assets/key/runes_key.png": "b6c516c46b9f57521badf3e304686577",
"assets/assets/themes/Math%2520Night.txt": "315364ea9dfa1f70813a5ea0d90748d8",
"assets/NOTICES": "bb6e7abae662bc5e0fcf2c06591374cb",
"assets/AssetManifest.bin": "bdef0f0db332efb5f5775108d594c23a",
"assets/fonts/MaterialIcons-Regular.otf": "f8363f2b0b3e73e8d970fc31d94ba56d",
"assets/AssetManifest.bin.json": "300efbe3eeff92de8f471442ad8a0be7",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"index.html": "00fe60ac9194041e0fdbd97d2891e9b4",
"/": "00fe60ac9194041e0fdbd97d2891e9b4",
"manifest.json": "c6bb7457453a462c0c103107f03472ba",
"flutter.js": "76f08d47ff9f5715220992f993002504"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
