#!/bin/bash
set -e

echo "=== VSLAST PREMIUM — FIX PWA YANDEX MAP ==="

if [ ! -f "pubspec.yaml" ]; then
  echo "ОШИБКА: запусти скрипт из корня проекта vslast_premium"
  exit 1
fi

JS_API_KEY="f1052ecf-4d78-454c-a175-b31bbf3da8a5"

echo "1. Создаём web/index.html с Yandex Maps JavaScript API..."

cat > web/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
  <base href="\$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">

  <meta
    name="description"
    content="Всласть — премиальная пекарня-кондитерская"
  >

  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
  >

  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default">
  <meta name="apple-mobile-web-app-title" content="Всласть">

  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png">

  <title>Всласть</title>
  <link rel="manifest" href="manifest.json">

  <!-- Yandex Maps JavaScript API -->
  <script
    src="https://api-maps.yandex.ru/2.1/?apikey=${JS_API_KEY}&lang=ru_RU"
    type="text/javascript">
  </script>

  <style>
    html,
    body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }

    #flutter_target {
      width: 100%;
      height: 100%;
    }

    #vslast-yandex-map {
      width: 100%;
      height: 100%;
      position: relative;
      overflow: hidden;
      background: #f5f1eb;
    }

    #vslast-yandex-map .map-loading {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #f5f1eb;
      color: #6f6258;
      font-family: Arial, sans-serif;
      font-size: 15px;
      z-index: 10;
    }
  </style>
</head>

<body>
  <div id="flutter_target"></div>

  <script>
    window.vslastYandexMapsReady = false;

    window.vslastYandexMapsPromise = new Promise(function(resolve) {
      if (typeof ymaps !== 'undefined') {
        ymaps.ready(function() {
          window.vslastYandexMapsReady = true;
          resolve();
        });
        return;
      }

      var timer = setInterval(function() {
        if (typeof ymaps !== 'undefined') {
          clearInterval(timer);

          ymaps.ready(function() {
            window.vslastYandexMapsReady = true;
            resolve();
          });
        }
      }, 100);
    });
  </script>

  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
HTML

echo "2. Создаём Web bridge для Yandex Maps..."

mkdir -p web

cat > web/vslast_yandex_map.js <<'JS'
(function () {
  'use strict';

  window.VslastYandexMap = {
    maps: {},

    create: function (elementId, latitude, longitude, zoom) {
      return window.vslastYandexMapsPromise.then(function () {
        var element = document.getElementById(elementId);

        if (!element) {
          throw new Error('Yandex map element not found: ' + elementId);
        }

        element.innerHTML = '';

        var map = new ymaps.Map(elementId, {
          center: [latitude, longitude],
          zoom: zoom || 15,
          controls: []
        }, {
          suppressMapOpenBlock: true
        });

        var marker = new ymaps.Placemark(
          [latitude, longitude],
          {},
          {
            preset: 'islands#brownDotIcon',
            draggable: false
          }
        );

        map.geoObjects.add(marker);

        this.maps[elementId] = {
          map: map,
          marker: marker
        };

        map.events.add('boundschange', function (event) {
          if (!event.get('newZoom')) {
            return;
          }

          var center = map.getCenter();

          window.dispatchEvent(
            new CustomEvent('vslast-map-moved', {
              detail: {
                id: elementId,
                latitude: center[0],
                longitude: center[1],
                zoom: map.getZoom()
              }
            })
          );
        });

        window.dispatchEvent(
          new CustomEvent('vslast-map-ready', {
            detail: {
              id: elementId
            }
          })
        );

        return map;
      }.bind(this));
    },

    moveTo: function (elementId, latitude, longitude, zoom) {
      var item = this.maps[elementId];

      if (!item) {
        return;
      }

      item.map.setCenter(
        [latitude, longitude],
        zoom || item.map.getZoom(),
        {
          duration: 400
        }
      );
    },

    getCenter: function (elementId) {
      var item = this.maps[elementId];

      if (!item) {
        return null;
      }

      var center = item.map.getCenter();

      return {
        latitude: center[0],
        longitude: center[1],
        zoom: item.map.getZoom()
      };
    },

    destroy: function (elementId) {
      var item = this.maps[elementId];

      if (!item) {
        return;
      }

      item.map.destroy();
      delete this.maps[elementId];
    }
  };
})();
JS

echo "3. Подключаем bridge в index.html..."

python3 - <<'PY'
from pathlib import Path

p = Path("web/index.html")
text = p.read_text()

needle = '<script src="flutter_bootstrap.js" async></script>'

replacement = '''<script src="vslast_yandex_map.js"></script>
  <script src="flutter_bootstrap.js" async></script>'''

if "vslast_yandex_map.js" not in text:
    text = text.replace(needle, replacement)

p.write_text(text)
PY

echo "4. Проверяем web-файлы..."

test -f web/index.html
test -f web/vslast_yandex_map.js

grep -q "api-maps.yandex.ru/2.1" web/index.html
grep -q "vslastYandexMapsPromise" web/index.html
grep -q "VslastYandexMap" web/vslast_yandex_map.js

echo "5. Очищаем старую Web-сборку..."

rm -rf build/web

echo "6. Собираем Flutter Web..."

flutter clean
flutter pub get
flutter build web --release

echo ""
echo "=== ГОТОВО ==="
echo ""
echo "Web-сборка создана в:"
echo "  build/web"
echo ""
echo "Yandex Maps JavaScript API подключён."
echo ""
echo "ВАЖНО:"
echo "Текущий delivery_address_screen.dart всё ещё содержит"
echo "_WebMapFallback для kIsWeb."
echo ""
echo "Поэтому сама карта пока НЕ появится в экране доставки."
echo ""
echo "Этот скрипт подготовил Web API и bridge."
echo "Следующим шагом нужно заменить Flutter Web-заглушку"
echo "на HtmlElementView с VslastYandexMap."
echo ""
echo "Не выполняй firebase deploy до следующего шага."
