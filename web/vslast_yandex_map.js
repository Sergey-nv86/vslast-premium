(function () {
  'use strict';

  window.VslastYandexMap = {
    maps: {},

    create: function (elementId, latitude, longitude, zoom) {
      var self = this;

      return window.vslastYandexMapsPromise.then(function () {
        return new Promise(function (resolve, reject) {
          var attempts = 0;
          var maxAttempts = 50;

          function tryCreate() {
            var element = document.getElementById(elementId);

            if (!element) {
              attempts++;

              if (attempts >= maxAttempts) {
                reject(
                  new Error(
                    'Yandex map element not found after waiting: ' +
                      elementId
                  )
                );

                return;
              }

              setTimeout(tryCreate, 50);
              return;
            }

            try {
              element.innerHTML = '';

              var map = new ymaps.Map(
                elementId,
                {
                  center: [latitude, longitude],
                  zoom: zoom || 15,
                  controls: []
                },
                {
                  suppressMapOpenBlock: true
                }
              );

              var marker = new ymaps.Placemark(
                [latitude, longitude],
                {},
                {
                  preset: 'islands#brownDotIcon',
                  draggable: false
                }
              );

              map.geoObjects.add(marker);

              self.maps[elementId] = {
                map: map,
                marker: marker
              };

              map.events.add(
                'boundschange',
                function (event) {
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
                }
              );

              window.dispatchEvent(
                new CustomEvent('vslast-map-ready', {
                  detail: {
                    id: elementId
                  }
                })
              );

              resolve(map);
            } catch (error) {
              reject(error);
            }
          }

          tryCreate();
        });
      });
    },

    moveTo: function (
      elementId,
      latitude,
      longitude,
      zoom
    ) {
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
