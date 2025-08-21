# container-qgis-server 

docker network create qgis

docker run -d --rm --name qgis-server --net=qgis --hostname=qgis-server \
              -v $(pwd)/data:/data:ro -p 5555:5555 \
              -e "QGIS_PROJECT_FILE=/data/world.qgs" \
              bcit.io/qgis-server

docker run -d --rm --name nginx --net=qgis --hostname=nginx \
              -v $(pwd)/data/nginx.conf:/etc/nginx/conf.d/default.conf:ro -p 8080:80 \
              bcit.io/nginx


# Currently using these plugins
(DataPlotly - Plugin ID: 1247)[https://plugins.qgis.org/plugins/DataPlotly/]
(GeoJson Renderer - Plugin ID: 2047)[https://plugins.qgis.org/plugins/qgis_server_render_geojson/#plugin-versions]
(Lizmap Server - Plugin ID: 2683)[https://plugins.qgis.org/plugins/lizmap_server/]