document.addEventListener "turbolinks:load", ->
  checkMap = ->
    mapContainer = $("[data-behavior='map-container']")
    initMap(mapContainer) if mapContainer.length

  initMap = (mapContainer) ->
    lat = mapContainer.data 'lat'
    long = mapContainer.data 'long'
    map = L.map(mapContainer.attr('id'), {scrollWheelZoom: false})
    osmUrl = 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    osmAttrib = 'Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
    osm = new L.TileLayer(osmUrl, { minZoom: 8, maxZoom: 18, attribution: osmAttrib})
    map.setView(new L.LatLng(lat, long), 15)
    map.addLayer(osm)
    new L.marker([lat, long]).addTo(map)

  checkMap()
