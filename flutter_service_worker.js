'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"index.html": "00fe60ac9194041e0fdbd97d2891e9b4",
"/": "00fe60ac9194041e0fdbd97d2891e9b4",
"assets/NOTICES": "ad97c348473116db59a0b076b14ea9ff",
"assets/assets/Runes/l/L.png": "062270024963385fa4ea6e6a1dac5263",
"assets/assets/Runes/y/Y.png": "2b42d40124ef67c32357ac2ac2d5cd11",
"assets/assets/Runes/k/K.png": "9379f24f4690d66c23b94ce9d2e6d188",
"assets/assets/Runes/s/S.png": "91338ad35142ed662f7d277a2e1046f1",
"assets/assets/Runes/u/U.png": "ec2f9c42d89c06f90003d3463bffa7f5",
"assets/assets/Runes/q/Q.png": "de0a8379d4deeabb05df09bcadfb6ecc",
"assets/assets/Runes/w/W.png": "4ef3493d92abfaba6849a9551b394875",
"assets/assets/Runes/i/I.png": "66f08e4b0d5b0a0d942c70a1ebdef9cb",
"assets/assets/Runes/m/M.png": "650264ea1515404e85509ea7c1e3b98e",
"assets/assets/Runes/v/V.png": "dcb5aca89714f28552d91e9e21c7f013",
"assets/assets/Runes/a/A.png": "52a04b68caa80bd2a7d7eac633b9bee0",
"assets/assets/Runes/f/F.png": "f8ed80bb2f2e1a6b6a2e9ff7b69bd8f6",
"assets/assets/Runes/j/J.png": "1ba8183fe18c7ffe246d35d46a9e07f8",
"assets/assets/Runes/x/X.png": "c0ed7ff4e324b5a0c0fc9537bf6a2bae",
"assets/assets/Runes/e/E.png": "3f2b1033cc72f6258a5854fbb37a994e",
"assets/assets/Runes/b/B.png": "79b66943002c9f29baf42f7b26a0eabe",
"assets/assets/Runes/p/P.png": "2438b9bdee81cfc1cd516cda137fd173",
"assets/assets/Runes/h/H.png": "fd174b802a87b9dc675c97f22a9d8859",
"assets/assets/Runes/d/D.png": "a1a0e29ff453004d400c677b63ef61f8",
"assets/assets/Runes/z/Z.png": "8302371bb07414a25d50531c59b3b880",
"assets/assets/Runes/o/O.png": "a2226c0e78b3bcaf55edb57fb4cbc932",
"assets/assets/Runes/t/T.png": "111dfb47999c3481a680ee3c4adcaffe",
"assets/assets/Runes/r/R.png": "cfaca90190b45003929ee89b9a651d05",
"assets/assets/Runes/n/N.png": "1960487b4891319123a7ba2c7c271441",
"assets/assets/Runes/g/G.png": "c0b7da9463afaac34ff027e43458ed88",
"assets/assets/Runes/c/C.png": "ecdf6578d7c78405f676a5f5cf9a9e7c",
"assets/assets/key/Runes_key.png": "b6c516c46b9f57521badf3e304686577",
"assets/assets/Initial%2520Letter%2520Pictures/l/L.png": "58b811d6accbad328bc7aff02284b5f1",
"assets/assets/Initial%2520Letter%2520Pictures/y/Y.png": "2f0338a7170f2d99f75cd14d249f2204",
"assets/assets/Initial%2520Letter%2520Pictures/k/K.png": "6483690f1b3a3a3153cb47c3bf3a72e6",
"assets/assets/Initial%2520Letter%2520Pictures/s/S.png": "418404c050374ec31e0fad247cf473f0",
"assets/assets/Initial%2520Letter%2520Pictures/u/U.png": "ee3f404811bb01f7ee550eab62e1b40c",
"assets/assets/Initial%2520Letter%2520Pictures/q/Q.png": "178f49044f4ea96d0c66c7dd135264dd",
"assets/assets/Initial%2520Letter%2520Pictures/w/W.png": "bb99e7f4e2c3c3fcee69e43224dc5b2b",
"assets/assets/Initial%2520Letter%2520Pictures/i/I.png": "293a0eeb41c4e9d70e23a85c11094b54",
"assets/assets/Initial%2520Letter%2520Pictures/m/M.png": "d6d0d4643274eaf4ed64da806085efd4",
"assets/assets/Initial%2520Letter%2520Pictures/v/V.png": "3d5cf93254d470e6b30176957e74ad18",
"assets/assets/Initial%2520Letter%2520Pictures/a/A.png": "8ec3a50bee0cf0cf97f56f932ecdb120",
"assets/assets/Initial%2520Letter%2520Pictures/f/F.png": "fdf2375dd0ffa2d7d1f76aab742ada5a",
"assets/assets/Initial%2520Letter%2520Pictures/j/J.png": "dd6299ad5cd8bd3c102a9372730c0e83",
"assets/assets/Initial%2520Letter%2520Pictures/x/X.png": "0c91e391883697acb7d289d4f015e5a4",
"assets/assets/Initial%2520Letter%2520Pictures/e/E.png": "6539a06d9a3706f67be84fb9e17b4e56",
"assets/assets/Initial%2520Letter%2520Pictures/b/B.png": "66c553a57cf73be6d9e10e4ba45d7912",
"assets/assets/Initial%2520Letter%2520Pictures/p/P.png": "89f4b00f07a9da68da65227898f8273f",
"assets/assets/Initial%2520Letter%2520Pictures/h/H.png": "c8d37abb22b502244c52a9dc91e3caa8",
"assets/assets/Initial%2520Letter%2520Pictures/d/D.png": "659be5a4e34528a67ff7ac38138860ff",
"assets/assets/Initial%2520Letter%2520Pictures/z/Z.png": "b6cd1e990564cd38ba4b62571dfddb08",
"assets/assets/Initial%2520Letter%2520Pictures/o/O.png": "97e2970c83be5c5d6fd171b437fe902a",
"assets/assets/Initial%2520Letter%2520Pictures/t/T.png": "cb8874b16dee8d786eb128503106e7d2",
"assets/assets/Initial%2520Letter%2520Pictures/r/R.png": "8675fabfbf969897f2cdc761d36259d1",
"assets/assets/Initial%2520Letter%2520Pictures/n/N.png": "df70b5c50e952037c3d5cc6290a8196e",
"assets/assets/Initial%2520Letter%2520Pictures/g/G.png": "784f3c772e05a43f3f63045015eef8c2",
"assets/assets/Initial%2520Letter%2520Pictures/c/C.png": "402d4e01af29dadff2565d31de3de9e5",
"assets/assets/themes/Math%2520Night.txt": "be37bf2443769c8a819dd7e1ffcccf4c",
"assets/assets/themes/Inspirational%2520Quotes.txt": "3ad460f8e01666c26062dabc240ab46b",
"assets/assets/themes/Fun%2520Facts%2520For%2520Kids.txt": "850d5575c27cad8d5ae09cf65acc8cac",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "b016ae49c261822659b8807d1400aed0",
"assets/fonts/MaterialIcons-Regular.otf": "a0deb786f60cfe5ab6861b9272d6b09e",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "029bd1d9d8fc1434fbd0a5d94fcf67b2",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/AssetManifest.json": "86584ecdad4b516023e219a31e0962fc",
"version.json": "dcb3e31dc89554c90b4fa420661062e9",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"main.dart.js": "f94b997d1cd1f382442784df5c9f4869",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"manifest.json": "c6bb7457453a462c0c103107f03472ba",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter_bootstrap.js": "762e197022b32564038574b85d24790a"};
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
